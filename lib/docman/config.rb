require 'singleton'
require 'hash_deep_merge'
require 'digest/md5'

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

    def merge_config_from_file(file)
      config = YAML::load_file(file)
      @config.deep_merge(config)
      @config['version'] = config['version'].nil? ? 1 : config['version']
      assign_to_self
    end

    def config_hash
      Digest::MD5.hexdigest(Marshal::dump(@unmutable_config))
    end

    def version
      @config['version']
    end

  end
end
