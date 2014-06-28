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
require 'docman/command'
require 'docman/composite_command'
require 'docman/builders/commands/create_symlink_cmd'
require 'docman/builders/commands/execute_script_cmd'
require 'docman/builders/commands/clean_changed_cmd'
require 'docman/builders/commands/git_commit_cmd'

module Docman
  class Application

    attr_reader :config, :options, :docroot_config
    attr_accessor :deploy_target

    include Singleton
    include Docman::Context

    def initialize
      # TODO: Define workspace properly
      @workspace_dir = Dir.pwd
      @config = Docman::Config.new(File.join(Pathname(__FILE__).dirname.parent, 'config', 'config.yaml'))
    end

    def merge_config_from_file(file)
      config = YAML::load_file(file)
      @config.deep_merge(config)
    end

    def init(name, repo)
      `mkdir #{name} && cd #{name} && git clone #{repo} config`
    end

    def build(deploy_target_name, state, options = false)
      @options = options
      @deploy_target = @config['deploy_targets'][deploy_target_name]
      @docroot_config = DocrootConfig.new(@workspace_dir, deploy_target)
      execute(state)
    end

    def deploy(deploy_target_name, name, type, version, options = false)
      @options = options
      @deploy_target = @config['deploy_targets'][deploy_target_name]
      @docroot_config = DocrootConfig.new(@workspace_dir, deploy_target)
      @docroot_config.states_dependin_on(name, version).keys.each do |state|
        execute(state, name)
      end
    end

    def execute(state, name = nil)
      params = @deploy_target
      params['state'] = state
      params['name'] = name
      Docman::Deployers::Deployer.create(params, self).perform
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
