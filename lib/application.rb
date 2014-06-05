require 'docman/version'
require 'yaml'
require 'pathname'
require 'fileutils'
require 'docman/git_util'
require 'docman/docroot_config'
require 'docman/docroot_controller'
require 'docman/exec'
require 'singleton'

module Docman
  class Application

    attr_reader :config, :options
    attr_accessor :deploy_target

    include Singleton

    def initialize
      # TODO: Define workspace properly
      @workspace_dir = Dir.pwd
      @config = YAML::load_file(File.join(Pathname(__FILE__).dirname.parent, 'config', 'config.yaml'))
    end

    def init(name, repo)
      `mkdir #{name} && cd #{name} && git clone #{repo} config`
    end

    def build(deploy_target, state, options = false)
      @options = options
      DocrootController.new(@workspace_dir, deploy_target).build(state)
    end

    def deploy(deploy_target, name, type, version, options = false)
      @options = options
      DocrootController.new(@workspace_dir, deploy_target).deploy(name, type, version)
    end

    def state(name, type, version)
      DocrootController.new(@workspace_dir, deploy_target).state(name, type, version)
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
