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
      `mkdir #{name} && cd #{name} && git clone #{repo} config`
    end

    def build(deploy_target_name, state, options = false)
      @options = options
      @deploy_target = @config['deploy_targets'][deploy_target_name]
      @deploy_target['name'] = deploy_target_name
      @docroot_config = DocrootConfig.new(@workspace_dir, deploy_target)
      execute('build', state)
    end

    def deploy(deploy_target_name, name, type, version, options = false)
      @options = options
      @deploy_target = @config['deploy_targets'][deploy_target_name]
      @deploy_target['name'] = deploy_target_name
      @docroot_config = DocrootConfig.new(@workspace_dir, deploy_target)
      @docroot_config.states_dependin_on(name, version).keys.each do |state|
        execute('deploy', state, name)
      end
    end

    def execute(action, state, name = nil)
      params = @deploy_target
      params['state'] = state
      params['action'] = action
      params['name'] = name
      params['environment'] = @deploy_target['environments'][state]
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
