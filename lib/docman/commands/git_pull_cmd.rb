module Docman
  class GitPullCmd < Docman::Command

    register_command :git_pull

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
    end

    def execute
      with_logging() do
        log "Git pull target"
        GitUtil.pull(@context['root']['full_build_path'])
      end
    end
  end
end