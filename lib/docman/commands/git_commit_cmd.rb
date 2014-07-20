module Docman
  class GitCommitCmd < Docman::Command

    register_command :git_commit

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
    end

    before_execute do
      unless GitUtil.repo_changed? @context['root']['full_build_path']
        raise NoChangesError, "Repo not changed, commit not needed" unless @context.need_rebuild?
      end
    end

    def execute
      message = "name: #{@context['name']} updated, state: #{@context.state_name}"
      with_logging(message) do
        GitUtil.commit(@context['root']['full_build_path'], @context['full_build_path'], message)
      end
    end
  end
end