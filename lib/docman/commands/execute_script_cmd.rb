
module Docman
  class ExecuteScriptCmd < Docman::Command

    register_command :script


    def validate_command
      raise Docman::CommandValidationError.new("Please provide 'execution_dir' param") if self['execution_dir'].nil?
      raise Docman::CommandValidationError.new("Please provide 'location' param") if self['location'].nil?
      raise Docman::CommandValidationError.new("Please provide 'context'") if @context.nil?
      raise Docman::CommandValidationError.new("Context should be of type 'Info'") unless @context.is_a? Docman::Info
      replace_placeholder(self['execution_dir'])
      replace_placeholder(self['location'])
      raise Docman::CommandValidationError.new("Directory #{self['execution_dir']} not exists") unless File.directory? self['execution_dir']
      raise Docman::CommandValidationError.new("Script #{self['location']} not exists") unless File.file? self['location']
    end

    def execute
      Dir.chdir self['execution_dir']
      logger.info "Script execution: #{self['location']}"
      params = self['params'].nil? ? '' : prepare_params(self['params'])
      `chmod 777 #{self['location']}`
      `chmod a+x #{self['location']}`
      logger.info `#{self['location']} #{params}`
      $?.exitstatus
    end

    def prepare_params(params)
      result = []
      params.each do |param|
        case param
          when 'environment'
            result << @context.environment_name
        end
      end
      result.join(' ')
    end

  end
end