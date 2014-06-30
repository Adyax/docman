module Docman
  class ExecuteScriptCmd < Docman::Command

    register_command :script


    def validate_command
      raise "Please provide 'dir' param" if self['dir'].nil?
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
      raise "Directory #{File.join(@context['docroot_config'].docroot_dir, self['dir'])} not exists" unless File.directory? File.join(@context['docroot_config'].docroot_dir, self['dir'])
    end

    def execute
      @context
      dir = File.join(@context['docroot_config'].docroot_dir, self['dir'])
      Dir.chdir dir
      logger.info Exec.do File.join(@context['full_path'], self['name'], true)
    end
  end
end