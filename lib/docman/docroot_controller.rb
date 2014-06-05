require 'docman/builders/builder'
require 'docman/builders/common_builder'
require 'docman/builders/git_builder'
require 'docman/deployers/deployer'
require 'docman/deployers/git_deployer'
require 'docman/deployers/common_deployer'

# TODO: make universal logging class.

module Docman
  class DocrootController

    attr_reader :docroot_dir

    def initialize(docroot_dir, deploy_target_name, options = {})
      @deploy_target = Docman::Application.instance.config['deploy_targets'][deploy_target_name]
      Docman::Application.instance.deploy_target = @deploy_target
      docroot_config = DocrootConfig.new(docroot_dir, @deploy_target)
      @deployer = Docman::Deployers::Deployer.create(@deploy_target['handler'], @deploy_target)
      @docroot_dir = docroot_dir
      @docroot_config = docroot_config
    end

    def deploy(name, type, version)
      puts "Deploy #{name}, type: #{type}"
      @docroot_config.states_dependin_on(name, version).each do |state_name, state|
        deploy_dir_chain(state_name, @docroot_config.info_by(name))
        @deployer.push(@docroot_config.root_dir, state_name)
      end
    end

    def build(state)
      build_recursive(state)
      @deployer.push(@docroot_config.root_dir, state)
    end

    def build_recursive(state, info = nil)
      info = info ? info : @docroot_config.structure
      build_dir(state, info)

      info['children'].each do |child|
        build_recursive(state, child)
      end
    end

    def deploy_dir_chain(state, info)
      @docroot_config.chain(info).each do |name, item|
        if item.need_rebuild?
          build_recursive(state, item)
          return
        elsif
          build_dir(state, item)
        end
      end
    end

    def build_dir(state, info)
      info.state = state
      @deployer.build(@docroot_config.root(info), info)
    end

  end

end