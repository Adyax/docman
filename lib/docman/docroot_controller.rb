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

# TODO: make universal logging class.

module Docman
  class DocrootController

    attr_reader :docroot_dir

    def initialize(docroot_dir, deploy_target_name, options = {})
      @deploy_target = Docman::Application.instance.config['deploy_targets'][deploy_target_name]
      Docman::Application.instance.deploy_target = @deploy_target
      docroot_config = DocrootConfig.new(docroot_dir, @deploy_target)
      @docroot_dir = docroot_dir
      @docroot_config = docroot_config
    end

    def deploy(name, type, version)
      puts "Deploy #{name}, type: #{type}"
      @docroot_config.states_dependin_on(name, version).keys.each do |state_name|
        deploy_dir_chain(state_name, @docroot_config.info_by(name))
        deployer_perform(state_name)
      end
    end

    def deployer_perform(state_name)
      root = @docroot_config.root
      root.state = state_name
      @deployer = Docman::Deployers::Deployer.create(@deploy_target, root)
      @deployer.perform
    end

    def build(state_name)
      build_recursive(state_name)
      deployer_perform(state_name)
    end

    def build_recursive(state, info = nil)
      info = info ? info : @docroot_config.structure
      build_dir(state, info)

      info['children'].each do |child|
        build_recursive(state, child)
      end
    end

    def deploy_dir_chain(state, info)
      @docroot_config.chain(info).values.each do |item|
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
      Docman::Builders::Builder.create(@deploy_target['builders'][info['type']], info).perform
    end

  end

end