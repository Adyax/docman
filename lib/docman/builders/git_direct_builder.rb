module Docman
  module Builders
    class GitDirectBuilder < Builder

      register_builder :git_direct_builder

      def execute
        execute_result = GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        # No commit hash for 'root' as it will be changed later
        @context['type'] == 'root' ? @context['build_path'] : execute_result
      end

      def changed?
        stored_version = @context.stored_version['result']
        # No commit hash for 'root' as it will be changed later
        repo_version = @context['type'] == 'root' ? @context['build_path'] : GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        stored_version != repo_version
      end

    end
  end
end
