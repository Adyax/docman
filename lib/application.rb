require 'docman/version'
require 'yaml'
require 'pathname'
require 'fileutils'
require 'docman/git_util'
require 'docman/docroot_config'
require 'docman/exec'
require 'docman/config'
require 'docman/logging'
require 'docman/context'
require 'singleton'
require 'logger'
require 'json'

require 'docman/builders/builder'
require 'docman/builders/dir_builder'
require 'docman/builders/symlink_builder'
require 'docman/builders/git_direct_builder'
require 'docman/builders/git_root_chain_builder'
require 'docman/builders/git_strip_builder'
require 'docman/builders/drupal_drush_builder'
require 'docman/deployers/deployer'
require 'docman/deployers/git_deployer'
require 'docman/deployers/common_deployer'
require 'docman/commands/command'
require 'docman/commands/composite_command'
require 'docman/commands/create_symlink_cmd'
require 'docman/commands/execute_script_cmd'
require 'docman/commands/clean_changed_cmd'
require 'docman/commands/git_commit_cmd'
require 'docman/commands/git_copy_repo_content_cmd'
require 'docman/taggers/tagger'
require 'docman/taggers/incremental_tagger'
require 'docman/taggers/option_tagger'

module Docman
  class Application < Docman::Command

    attr_reader :config, :docroot_config
    attr_accessor :deploy_target, :options, :force, :commit_count

    include Singleton
    include Docman::Context

    def initialize
      # TODO: Define workspace properly
      @workspace_dir = Dir.pwd
      @config = Docman::Config.new(File.join(Pathname(__FILE__).dirname.parent, 'config', 'config.yaml'))
      @force = false
      @commit_count = 0
    end

    def init(name, repo, options)
      branch = options['branch'] ? options['branch'] : 'master'
      `mkdir #{name}`
      Dir.chdir name
      GitUtil.clone_repo(repo, 'config', 'branch', branch, true, 1)
      #Dir.chdir File.join(name, 'config')
      #`git checkout #{branch} & git branch -u origin #{branch}`
    end

    def with_rescue(write_to_file = true)
      failed_filepath = File.join(@workspace_dir, 'failed')
      if File.file?(failed_filepath)
        log 'Last operation failed, forced rebuild mode'
        FileUtils.rm_f failed_filepath
        @force = true
      end
      yield
    rescue Exception => e
      log "Operation failed: #{e.message}", 'error'
      if write_to_file
        File.open(failed_filepath, 'w') {|f| f.write(e.message) }
      end
      raise e
    end

    def build(deploy_target_name, state, options = false)
      with_rescue do
        @options = options
        @deploy_target = @config['deploy_targets'][deploy_target_name]
        @deploy_target['name'] = deploy_target_name
        @docroot_config = DocrootConfig.new(@workspace_dir, deploy_target)
        execute('build', state, nil, options['tag'])
      end
    end

    def deploy(deploy_target_name, name, type, version, options = false)
      result = nil
      with_rescue do
        @options = options
        @deploy_target = @config['deploy_targets'][deploy_target_name]
        raise "Wrong deploy target: #{deploy_target_name}" if @deploy_target.nil?
        @deploy_target['name'] = deploy_target_name
        @docroot_config = DocrootConfig.new(@workspace_dir, deploy_target)
        @docroot_config.states_dependin_on(name, version).keys.each do |state|
          execute('deploy', state, name)
          write_environment(@deploy_target['states'][state], name)
          write_state state
          result = state
        end
      end
      result
    end

    def template(name, options = false)
      with_rescue(false) do
        @options = options
        @docroot_config = DocrootConfig.new(@workspace_dir, nil)
        project = @docroot_config.project(name)
        unless project['template'].nil?
          Dir.chdir project['full_build_path']
          Exec.do "#{Application::bin}/project-template.sh #{project['template']}"
          log "Project had been initialized with template: #{project['template']}"
        end
      end
    end

    def drush(env, site, command)
      with_rescue(false) do
        cmd = "drush env: '#{env}', site: '#{site}', '#{command}'"
        log cmd
        path = Dir.pwd
        branch = 'commands'
        current_branch = GitUtil.branch
        GitUtil.exec("fetch")
        have_branch = Exec.do("git ls-remote --exit-code . origin/#{branch} &> /dev/null")
        log have_branch
        if have_branch
          GitUtil.exec("checkout #{branch}")
          GitUtil.exec("pull origin #{branch}")
        else
          GitUtil.exec("checkout --orphan #{branch}")
          GitUtil.exec("rm --cached -r .", false)
          GitUtil.exec("clean -f -d", false)
        end
        File.open(File.join(path, 'commands'), 'a') {|f| f.puts cmd}
        GitUtil.exec("add commands")
        GitUtil.exec("commit -m 'Added command'")
        GitUtil.exec("push origin #{branch}")
        GitUtil.exec("checkout #{current_branch}")
      end
    end

    def info(command, file, options = false)
      result = {}
      @docroot_config = DocrootConfig.new(@workspace_dir, deploy_target)
      if (command == 'full')
        result['states'] = Docman::Application.instance.config['deploy_targets']['git_target']['states']
        result['environments'] = Docman::Application.instance.config['environments']

        projects = {}
        info = @docroot_config.structure
        @docroot_config.chain(info).values.each do |item|
          projects.merge! info_recursive(item, command)
        end
        result['projects'] = projects
      else
        info = @docroot_config.structure
        @docroot_config.chain(info).values.each do |item|
          result.merge! info_recursive(item, command)
        end
      end
      File.open(file, 'w') {|f| f.write result.to_json}
      result
    end

    def info_recursive(info, command)
      result = {}
      case command
        when 'list'
          result[info['name']] = info['repo'] if info.key?('repo')
        when 'full'
          info_clone = info.clone
          info_clone.delete('docroot_config')
          info_clone.delete('children')
          info_clone.delete('parent')
          info_clone.delete('root')
          result[info['name']] = info_clone
      end
      info['children'].each do |child|
        result.merge! info_recursive(child, command)
      end
      result
    end

    def write_state state
      filepath = File.join(@workspace_dir, 'state')
      File.open(filepath, 'w') { |file| file.write(state) }
    end

    def write_environment(env, name)
      environment = environment(env)

      properties = {}
      properties['ENV'] = env
      unless environment.nil?
        unless environment['previous'].nil?
          unless environment['previous'][name].nil?
            properties['project_last_result'] = environment['previous'][name]['result'] unless environment['previous'][name]['result'].nil?
            unless environment['previous'][name]['context'].nil?
              properties['temp_path'] = environment['previous'][name]['context']['temp_path'] unless environment['previous'][name]['context']['temp_path'].nil?
            end
          end
        end
      end

      properties['last_project'] = name
      filepath = File.join(@workspace_dir, 'last_deploy.properties')
      File.open(filepath, 'w') do |file|
        properties.each {|key, value| file.puts "#{key}=#{value}\n" }
      end
    end

    def execute(action, state, name = nil, tag = nil)
      params = Marshal.load(Marshal.dump(@deploy_target))
      params['state'] = state
      params['action'] = action
      params['name'] = name
      params['tag'] = tag ? tag : state + '-' + Time.now.strftime("%Y-%m-%d-%H-%M-%S")
      params['environment'] = @config['environments'][@deploy_target['states'][state]]
      params['environment_name'] = @deploy_target['states'][state]
      Docman::Deployers::Deployer.create(params, nil, self).perform
    end

    def force?
      @force or @options[:force]
    end

    def self.root
      Pathname(__FILE__).dirname.parent
    end

    def environment(name)
      @config['environments'][name]
    end

    def self.bin
      File.join root, 'bin'
    end

    def self.lib
      File.join root, 'lib'
    end

  end

end
