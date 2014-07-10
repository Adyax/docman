require 'docman/context'

module Docman
  class Info < Hash

    include Docman::Context

    attr_accessor :need_rebuild

    def initialize(hash = {})
      super
      hash.each_pair do |k, v|
        self[k] = v
      end
      self['build_type'] = self['docroot_config'].deploy_target['builders'][self['type']]['handler']
      @need_rebuild = Hash.new
    end

    def version
      self['states'][self['state']].nil? ? nil : self['states'][self['state']]['version']
    end

    def version_type
      self['states'][self['state']].nil? ? nil : self['states'][self['state']]['type']
    end

    def describe(type = 'short')
      properties_info(%w(name type build_type))
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
      return @need_rebuild[self['state']] if not @need_rebuild.nil? and @need_rebuild.has_key? self['state'] and not @need_rebuild[self['state']].nil?
      @need_rebuild[self['state']] = _need_rebuild?
      if @need_rebuild[self['state']]
        set_rebuild_recursive(self, true)
      end
      @need_rebuild[self['state']]
    end

    def set_rebuild_recursive(obj, value)
      obj.need_rebuild[self['state']] = value
      if obj.has_key?('children')
        obj['children'].each do |info|
          set_rebuild_recursive(info, value)
        end
      end
    end

    def _need_rebuild?
      return true if Docman::Application.instance.force?
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

    def commands(type, hook)
       if self.has_key? 'actions' and self['actions'].has_key? type and self['actions'][type].has_key? hook
         return self['actions'][type][hook]
       end
      []
    end

    def environment
      self['docroot_config'].deploy_target['environments'][self['state']]
    end

  end
end