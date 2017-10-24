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
              build_file = Dir.glob([File.join(@context['docroot_config'].config_dir, yaml_file_name), File.join(@context['full_build_path'], yaml_file_name)]).first
              if not build_file.nil?
                build_file_yaml = YAML::load_file(build_file)
                commands = build_file_yaml[self['stage']]
                source = yaml_file_name
              end
            end
            if self['source_type'] == 'inline'
              commands = self['commands']
              source = 'inline'
            end
            unless commands.nil?
              commands.each do |cmd|
                logger.info "Execute from #{source}: #{cmd}"
                logger.info `#{cmd}`
                if $?.exitstatus > 0
                  raise "Command #{cmd} was failed"
                end
              end
            end
          end
        end
      end
    end
  end
end