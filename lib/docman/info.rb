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
      return TRUE if Docman::Application.instance.options[:force]
      return TRUE unless File.directory? self['full_build_path']
      info_filename = File.join(self['full_build_path'], 'info.yaml')
      return TRUE unless File.file?(info_filename)
      version = YAML::load_file(info_filename)
      return TRUE if version['type'] != self['type']
      return TRUE if version['build_type'] != self['build_type']
      false
    end

    def state=(state)
      self['state'] = state
    end

  end
end