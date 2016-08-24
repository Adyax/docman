require 'docman/builders/builder'
require 'docman/builders/dir_builder'
require 'docman/builders/git_direct_builder'
require 'docman/builders/git_root_chain_builder'
require 'docman/builders/git_strip_builder'
require 'docman/builders/drupal_drush_builder'
require 'docman/deployers/deployer'
require 'docman/deployers/git_deployer'
require 'docman/deployers/common_deployer'

# TODO: make universal logging class.

module Docman
  class DocrootController

    attr_reader :docroot_dir, :docroot_config

    def initialize(docroot_dir, deploy_target_name, options = {})
      @deploy_target = Docman::Application.instance.config['deploy_targets'][deploy_target_name]
      @deploy_target_name = deploy_target_name
      Docman::Application.instance.deploy_target = @deploy_target
      docroot_config = DocrootConfig.new(docroot_dir, @deploy_target)
      @docroot_dir = docroot_dir
      @docroot_config = docroot_config
    end

    def build(state_name)
      execute(state_name)
    end

    def deploy(name, type, version)
      @docroot_config.states_dependin_on(name, version).keys.each do |state_name|
        execute(state_name, name)
      end
    end

    def execute(state, name = nil)
      #Docman::Application.instance.config.environment(state_name, @deploy_target_name)
      params = @deploy_target
      params['state'] = state
      params['name'] = name
      Docman::Deployers::Deployer.create(params, self).perform
    end

  end

end