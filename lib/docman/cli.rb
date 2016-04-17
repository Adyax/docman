require 'thor'
require 'application'
require 'docman/git_util'
require 'json'

module Docman
  class CLI < Thor

    # TODO: add proper descriptions.

    desc 'init "dirname" "repo"', 'Initialize docroot in "dirname" from config repo "repo"'
    method_option :force, :aliases => '-f', :desc => 'Force init'
    method_option :skip, :aliases => '-s', :desc => 'Skip if docroot initialized already'
    option :branch
    def init(name, repo)
      if File.directory? name
        say("Directory #{name} already exists")
        if options[:force]
          FileUtils.rm_r(name)
        elsif options[:skip]
         if File.directory? File.join(name, 'config') and GitUtil.repo? File.join(name, 'config')
           return
         else
           FileUtils.rm_r(name)
         end
        else
          choice = ask('Are you sure you want do delete existing docroot? Type "yes" if you agree.')
          if choice == 'yes'
            FileUtils.rm_r(name)
          elsif
          Kernel::abort 'Exit'
          end
        end
      end

      puts "Init docroot directory #{name} and retrieve config from provided repo."
      Application.instance.init(name, repo, options)
      say('Complete!', :green)
    end

    desc 'build', 'Build docroot'
    method_option :force, :aliases => '-f', :desc => 'Force full rebuild'
    option :tag
    def build(deploy_target, state)
      get_to_root_dir
      if options[:force]
        FileUtils.rm_r('master') if File.directory? 'master'
      end
      Application.instance.build(deploy_target, state, options)
      say('Complete!', :green)
    end

    desc 'deploy', 'Deploy to target'
    method_option :force, :aliases => '-f', :desc => 'Force full deploy'
    def deploy(deploy_target, name, type, version)
      get_to_root_dir
      if version.start_with?('state_')
        state = version.partition('_').last
        build(deploy_target, state)
      else
        result = Application.instance.deploy(deploy_target, name, type, version, options)
        say(result, :green)
      end
    end

    desc 'bump', 'Bump version'
    method_option :next, :aliases => '-n', :desc => 'Automatically use next version number'
    #option :state
    #option :skip
    def bump(state = nil, skip = nil)
      version_number = options[:next] ? 'next' : 'ask'

      Exec.do "#{Application::bin}/bump-version.sh #{state} #{version_number} #{skip}"
      say('Complete!', :green)
    end

    desc 'template', 'Reinit project from template'
    method_option :force, :aliases => '-f', :desc => 'Force project override with template'
    option :name
    def template(name = nil)
      current_dir_name = File.basename(Dir.pwd)
      get_to_root_dir
      name = current_dir_name if name.nil?
      Application.instance.template(name, options)
      say('Complete!', :green)
    end

    desc 'drush', 'Execute remote drush commands'
    def drush(drush_alias, command)
      env = drush_alias.partition('.').first.partition('@').last
      site = drush_alias.partition('.').last
      Application.instance.drush(env, site, command)
      say('Complete!', :green)
    end

    desc 'info', 'Get info'
    method_option :force, :aliases => '-f', :desc => 'Force full rebuild'
    option :tag
    def info(command, file)
      say(Application.instance.info(command, file, options).to_json);
      # say('Complete!', :green)
    end

    no_commands {
      def current_dir_has_config_dir
        File.directory?('config')
      end

      def config_dir?
        raise 'ERROR: No config directory in docroot' unless current_dir_has_config_dir
      end

      def get_to_root_dir
        until current_dir_has_config_dir
          raise 'ERROR: No config directory in docroot' if File.basename(Dir.pwd) == '/'
          Dir.chdir('..')
        end
      end
    }
  end
end