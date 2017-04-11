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

    def merge_config_from_file(docroot_config_dir, config_file)
      file = File.join(docroot_config_dir, config_file)
      if File.file?(file)
        config = YAML::load_file(file)
        unless config.nil?
          @config.deep_merge(config)
          @config['version'] = config['version'].nil? ? 1 : config['version']
        end
        unless config['scenario'].nil?
          scenario_config_file = File.join(Pathname(__FILE__).dirname.parent.parent, 'config', 'scenarios', config['scenario'], 'config.yaml')
          if File.file? scenario_config_file
            scenario_config = YAML::load_file(scenario_config_file)
            @config.deep_merge(scenario_config)
          end
        end
        assign_to_self
      end
    end

    def config_hash
      Digest::MD5.hexdigest(Marshal::dump(@unmutable_config))
    end

    def version
      @config['version']
    end

  end
end
