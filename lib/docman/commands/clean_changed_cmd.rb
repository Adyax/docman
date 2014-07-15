module Docman
  class CleanChangedCmd < Docman::Command

    register_command :clean_changed

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
    end

    #TODO: Keep files feature
    def execute
      if File.directory? @context['full_build_path']
        if @context.need_rebuild?
          return false if @context['type'] == 'dir'
          return false if @context['type'] == 'root' and @context['build_type'] == :dir_builder and not GitUtil.repo?(@context['full_build_path'])
          return false if @context['type'] == 'root' and @context['build_type'] == :git_direct_builder and GitUtil.repo?(@context['full_build_path'])
          if @context['type'] == 'repo'
            if @context['build_type'] == :git_direct_builder
              return false if GitUtil.repo?(@context['full_build_path'])
            end
          end
          log("Remove #{@context['full_build_path']}")
          FileUtils.rm_rf @context['full_build_path']
        end
      end
    end

  end
end