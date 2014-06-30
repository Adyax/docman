require 'docman/context'

module Docman
  class Info < Hash

    include Docman::Context

    def initialize(hash = {})
      super
      hash.each_pair do |k, v|
        self[k] = v
      end
      self['build_type'] = self['docroot_config'].deploy_target['builders'][self['type']]['handler']
    end

    def version
      self['states'][self['state']].nil? ? nil : self['states'][self['state']]['version']
    end

    def version_type
      self['states'][self['state']].nil? ? nil : self['states'][self['state']]['type']
    end

    def describe(type = 'short')
      properties_info(['name', 'type', 'build_type'])
    end

    def write_info(result)
      to_save = {}
      to_save['state'] = self['state']
      to_save['version_type'] = self.version_type unless self.version_type.nil?
      to_save['version'] = self.version unless self.version.nil?
      to_save['result'] = result
      to_save['type'] = self['type']
      to_save['build_type'] = self['build_type']

      File.open(File.join(self['full_build_path'], 'info.yaml'), 'w') {|f| f.write to_save.to_yaml}
      to_save
    end

    def need_rebuild?
      return @need_rebuild unless @need_rebuild.nil?
      @need_rebuld = _need_rebuild?
    end

    def _need_rebuild?
      return true if Docman::Application.instance.options[:force]
      return true unless File.directory? self['full_build_path']
      v = stored_version
      return true unless v
      return true if v['type'] != self['type']
      return true if v['build_type'] != self['build_type']
      return true if (not v['version'].nil? and v['version'] != self.version)
      return true if (not v['version_type'].nil? and v['version_type'] != self.version_type)
      unless v['state'].nil?
        return true if v['state'] != self['state']
      end
      false
    end

    def stored_version
      info_filename = File.join(self['full_build_path'], 'info.yaml')
      return false unless File.file?(info_filename)
      YAML::load_file(info_filename)
    end

    def state=(state)
      self['state'] = state
    end

    def disabled?
      unless self['status'].nil?
        return self['status'] == 'disabled'
      end
      false
    end

  end
end