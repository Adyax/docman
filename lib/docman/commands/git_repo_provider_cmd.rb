module Docman
  class GitRepoProvider < Docman::Command

    attr_reader :version

    register_command :git_repo_provider

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
    end

    def execute
      @execute_result = get_content
      # No commit hash for 'root' as it will be changed later
      @version = @context['type'] == 'root' ? @context['build_path'] : @execute_result
    end

    def changed?
      stored_version = @context.stored_version['result']
      @last_version = GitUtil.last_revision(self['target_path'])
      # TODO: diff with remote instead of get
      v = version(true)
      stored_version != v
    end

    def get_content
      GitUtil.get(@context['repo'], self['target_path'], @context.version_type, @context.version, true, 1)
    end

    def changed_from_last_version?
      @last_version != @version
    end

    def version(remote = false)
      # branch = remote ? "origin/#{@context.version}" : nil
      # @context['type'] == 'root' ? @context['build_path'] : GitUtil.last_revision(self['target_path'], branch)
      @context['type'] == 'root' ? @context['build_path'] : get_content
    end

  end
end