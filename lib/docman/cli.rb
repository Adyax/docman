require 'thor'
require 'application'
require 'docman/git_util'

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
      config_dir?
      if options[:force]
        FileUtils.rm_r('master') if File.directory? 'master'
      end
      Application.instance.build(deploy_target, state, options)
      say('Complete!', :green)
    end

    desc 'deploy', 'Deploy to target'
    method_option :force, :aliases => '-f', :desc => 'Force full deploy'
    def deploy(deploy_target, name, type, version)
      if version.start_with?('state_')
        state = version.partition('_').last
        build(deploy_target, state)
      else
        config_dir?
        result = Application.instance.deploy(deploy_target, name, type, version, options)
        say(result, :green)
      end
    end

    desc 'bump', 'Bump version'
    #option :state
    #option :skip
    def bump(state = nil, skip = nil)
      # if state
      #   Exec.do "#{Application::bin}/bump-version.sh #{state}"
      # else
      #   Exec.do "#{Application::bin}/bump-version.sh"
      # end
      Exec.do "#{Application::bin}/bump-version.sh #{state} #{skip}"
      say('Complete!', :green)
    end

    no_commands {
      def config_dir?
        raise 'ERROR: No config directory in docroot' unless File.directory?('config')
      end
    }
  end
end