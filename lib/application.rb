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

require 'docman/builders/builder'
require 'docman/builders/dir_builder'
require 'docman/builders/git_direct_builder'
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
require 'docman/taggers/tagger'
require 'docman/taggers/incremental_tagger'
require 'docman/taggers/option_tagger'

module Docman
  class Application < Docman::Command

    attr_reader :config, :docroot_config
    attr_accessor :deploy_target, :options, :force

    include Singleton
    include Docman::Context

    def initialize
      # TODO: Define workspace properly
      @workspace_dir = Dir.pwd
      @config = Docman::Config.new(File.join(Pathname(__FILE__).dirname.parent, 'config', 'config.yaml'))
      @force = false
    end

    def init(name, repo)
      `mkdir #{name} && cd #{name} && git clone --depth 1 #{repo} config`
    end

    def with_rescue
      failed_filepath = File.join(@workspace_dir, 'failed')
      if File.file?(failed_filepath)
        log 'Last operation failed, forced rebuild mode'
        FileUtils.rm_f failed_filepath
        @force = true
      end
      yield
    rescue Exception => e
      log "Operation failed: #{e.message}", 'error'
      File.open(failed_filepath, 'w') {|f| f.write('Failed!') }
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
      with_rescue do
        @options = options
        @deploy_target = @config['deploy_targets'][deploy_target_name]
        raise "Wrong deploy target: #{deploy_target_name}" if @deploy_target.nil?
        @deploy_target['name'] = deploy_target_name
        @docroot_config = DocrootConfig.new(@workspace_dir, deploy_target)
        @docroot_config.states_dependin_on(name, version).keys.each do |state|
          execute('deploy', state, name)
        end
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

    def self.bin
      File.join root, 'bin'
    end

    def self.lib
      File.join root, 'lib'
    end

  end

end
