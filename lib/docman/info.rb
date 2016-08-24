require 'docman/context'

module Docman
  class Info < Hash

    include Docman::Context

    attr_accessor :need_rebuild, :build_mode, :state_name

    def initialize(hash = {})
      super
      hash.each_pair do |k, v|
        self[k] = v
      end
      self['build_type'] = self['docroot_config'].deploy_target['builders'][self['type']]['handler'] unless self['docroot_config'].deploy_target.nil?
      @need_rebuild = Hash.new
      @changed = Hash.new
      @state_name = nil
      unless self['docroot_config'].deploy_target.nil?
        if self.has_key? 'states'
          self['states'].each_pair do |name, state|
            if state.has_key?('source')
              if state['source']['type'] == :retrieve_from_repo
                @state_name = name
                repo = state['source']['repo'] == :project_repo ? self['repo'] : state['source']['repo']
                external_state_info = read_yaml_from_file(repo, self['states_path'], state['source']['branch'], state['source']['file'])
                state.deep_merge! external_state_info unless external_state_info.nil? or state.nil?
              end
            end
          end
        end
      end
    end

    def read_yaml_from_file(repo, path, version, filename)
      GitUtil.get(repo, path, 'branch', version, true, 1, true)
      filepath = File.join(path, filename)
      return YAML::load_file(filepath) if File.file? filepath
      nil
    rescue StandardError => e
      raise "Error in info file: #{filepath}, #{e.message}"
    end

    def version(options = {})
      state(options).nil? ? nil : state(options)['version']
    end

    def version_type(options = {})
      state(options).nil? ? nil : state(options)['type']
    end

    def describe(type = 'short')
      properties_info(%w(name type build_type))
    end

    def write_info(result)
      to_save = {}
      to_save['state'] = @state_name
      to_save['version_type'] = self.version_type unless self.version_type.nil?
      to_save['version'] = self.version unless self.version.nil?
      to_save['result'] = result
      to_save['type'] = self['type']
      to_save['build_type'] = self['build_type']

      File.open(File.join(self['full_build_path'], 'info.yaml'), 'w') {|f| f.write to_save.to_yaml}
      to_save
    end

    def changed?
      #TODO: need refactor
      return @changed[@state_name] if not @changed.nil? and @changed.has_key? @state_name and not @changed[@state_name].nil?
      @changed[@state_name] = false
      if need_rebuild?
        @changed[@state_name] = true
      end
      @changed[@state_name]
    end

    def need_rebuild?
      return @need_rebuild[@state_name] if not @need_rebuild.nil? and @need_rebuild.has_key? @state_name and not @need_rebuild[@state_name].nil?
      @need_rebuild[@state_name] = _need_rebuild?
      if @need_rebuild[@state_name]
        set_rebuild_recursive(self, true)
      end
      @need_rebuild[@state_name]
    end

    def set_rebuild_recursive(obj, value)
      obj.need_rebuild[@state_name] = value
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
      # return true if (not v['version'].nil? and v['version'] != self.version)
      @changed[@state_name] = true if (not v['version'].nil? and v['version'] != version)
      return true if (not v['version_type'].nil? and v['version_type'] != version_type)
      unless v['state'].nil?
        # return true if v['state'] != @state_name
        @changed[@state_name] = true if v['state'] != @state_name
      end
      false
    end

    #TODO: check if info.yaml needed for local state
    def stored_version
      info_filename = File.join(self['full_build_path'], 'info.yaml')
      return false unless File.file?(info_filename)
      YAML::load_file(info_filename)
    end

    def state(options = {})
      states(options)[@state_name]
    end

    def states(options = {})
      if options[:type] == 'root' and self['type'] == 'root_chain'
        self['root_repo_states']
      else
        self['states']
      end
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

    def environment_name
      self['docroot_config'].deploy_target['states'][@state_name] unless self['docroot_config'].deploy_target.nil?
    end

  end
end