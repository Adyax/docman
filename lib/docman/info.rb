module Docman
  class Info < Hash

    def initialize(hash = {})
      super
      hash.each_pair do |k, v|
        self[k] = v
      end
      self['build_type'] = self['docroot_config'].deploy_target['builders'][self['type']]['type']
    end

    def version
      self['states'][self['state']].nil? ? nil : self['states'][self['state']]['version']
    end

    def version_type
      self['states'][self['state']].nil? ? nil : self['states'][self['state']]['type']
    end

    def write_info(result)
      to_save = {}
      to_save['state'] = self['state']
      to_save['version_type'] = self.version_type unless self.version_type.nil?
      to_save['version'] = self.version unless self.version.nil?
      # to_save['ref'] = result
      to_save['type'] = self['type']
      to_save['build_type'] = self['build_type']

      File.open(File.join(self['full_build_path'], 'info.yaml'), 'w') {|f| f.write to_save.to_yaml}
    end

    def need_rebuild?
      return true if Docman::Application.instance.options[:force]
      return true unless File.directory? self['full_build_path']
      info_filename = File.join(self['full_build_path'], 'info.yaml')
      return true unless File.file?(info_filename)
      version = YAML::load_file(info_filename)
      return true if version['type'] != self['type']
      return true if version['build_type'] != self['build_type']
      return true if (not version['version'].nil? and version['version'] != self.version)
      return true if (not version['version_type'].nil? and version['version_type'] != self.version_type)
      return true if (not version['state'].nil? and version['state'] != self['state'])
      false
    end

    def state=(state)
      self['state'] = state
    end

  end
end