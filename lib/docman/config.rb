require 'singleton'
require 'hash_deep_merge'
require 'digest/md5'
require 'json'

module Docman
  class Config < Hash

    attr_reader :unmutable_config

    def initialize(file)
      super
      @config = YAML::load_file(file)
      assign_to_self
    end

    def assign_to_self
      @config.each_pair do |k, v|
        self[k] = v
      end
      @unmutable_config = Marshal::load(Marshal.dump(@config))
    end

    def merge_config_from_file(docroot_config_dir, config_file, options = nil)
      file = File.join(docroot_config_dir, config_file)
      if File.file?(file)
        config = YAML::load_file(file)
        unless options[:config_repo].nil? || config.nil?
          scenarios_path = File.join(docroot_config_dir, '/../', 'scenarios')
          `rm -fR #{scenarios_path}` if File.directory? scenarios_path
          GitUtil.clone_repo(options[:config_repo], scenarios_path, 'branch', options[:config_repo_branch], true, 1)
          config = merge_scenarios_configs(config, scenarios_path)
        end
      end
      unless config.nil?
        @config.deep_merge!(config)
        @config['version'] = config['version'].nil? ? 1 : config['version']
      end

      assign_to_self
    end

    def merge_scenarios_configs(config, scenarios_path)
      scenarios_config = {}
      if config['scenarios']
        config['scenarios'].each do |scenario|
          scenario_config_file = File.join(scenarios_path, 'scenarios', scenario, 'config.yaml')
          if File.file? scenario_config_file
            scenario_config = merge_scenarios_configs(YAML::load_file(scenario_config_file), scenarios_path)
            scenarios_config.deep_merge!(scenario_config)
          end
        end
      end
      scenarios_config.deep_merge!(config)
    end

    def config_hash
      Digest::MD5.hexdigest(Marshal::dump(@unmutable_config))
    end

    def version
      @config['version']
    end

  end
end
