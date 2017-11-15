module Docman
  class YamlExecuteCmd < Docman::Command

    register_command :yaml_execute

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
      raise "Both file & inline could not be se for this command" if self['yaml_file_name'] && self['inline']
    end

    before_execute do
      self['source_type'] = 'inline' if self['source_type'].nil?
    end

    def execute
      with_logging('yaml_execute') do
        Dir.chdir @context['full_build_path']
        if self['environments'].nil? || self['environments'] == 'all' || self['environments'].include?(@context.environment_name)
          if self['providers'].nil? || self['providers'] == 'all' || self['providers'].include?(@context['provider'])
            commands = nil
            if self['source_type'] == 'file'
              yaml_file_name = self['yaml_file_name'].nil? ? '{unipipe,.unipipe,drupipe,.drupipe,build,.build}.{yaml,yml}' : self['yaml_file_name']
              search_pathes = []
              if @context['name'] == 'master'
                search_pathes.push File.join(@context['docroot_config'].config_dir, yaml_file_name)
              end
              search_pathes.push File.join(@context['full_build_path'], yaml_file_name)
              build_file = Dir.glob(search_pathes).first
              if not build_file.nil?
                build_file_yaml = YAML::load_file(build_file)
                commands = build_file_yaml[self['stage']]
                source = yaml_file_name
              end
            end
            chdir = ''
            if self['source_type'] == 'inline'
              commands = self['commands']
              source = 'inline'
              if self.has_key?('exec_dir')
                chdir = self['exec_dir']
              end
            end
            chdir_full = File.join(@context['full_build_path'], chdir)
            Dir.chdir chdir_full
            unless commands.nil?
              commands.each do |cmd|
                logger.info "Execute in #{chdir_full} from #{source}: #{cmd}"
                logger.info `#{cmd}`
                if $?.exitstatus > 0
                  raise "Command #{cmd} was failed"
                end
              end
            end
            Dir.chdir @context['full_build_path']
          end
        end
      end
    end
  end
end