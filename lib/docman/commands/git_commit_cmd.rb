module Docman
  class GitCommitCmd < Docman::Command

    register_command :git_commit

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
    end

    def before_execute
      @not_execute = true unless GitUtil.repo_changed? @context['root']['full_build_path']
    end

    def execute
      message = "name: #{@context['name']} updated, state: #{@context['state']}"
      GitUtil.commit(@context['root']['full_build_path'], @context['full_build_path'], message)
    end
  end
end