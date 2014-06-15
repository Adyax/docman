module Docman
  class CleanChangedCmd < Docman::Command

    register_command :clean_changed

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
    end

    def execute
      if File.directory? @context['full_build_path']
        FileUtils.rm_r @context['full_build_path'] if @context.need_rebuild?
      end
    end
  end
end