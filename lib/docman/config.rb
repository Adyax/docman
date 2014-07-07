require 'singleton'
require 'hash_deep_merge'
require 'digest/md5'

module Docman
  class Config < Hash

    def initialize(file)
      super
      @config = YAML::load_file(file)
      assign_to_self
    end

    def assign_to_self
      @config.each_pair do |k, v|
        self[k] = v
      end
    end

    def merge_config_from_file(file)
      config = YAML::load_file(file)
      @config.deep_merge(config)
      assign_to_self
    end

    def hash(object)
      Digest::MD5.hexdigest(Marshal::dump(object))
    end

  end
end
