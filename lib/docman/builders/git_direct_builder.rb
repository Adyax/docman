module Docman
  module Builders
    class GitDirectBuilder < Builder

      register_builder :git_direct_builder

      def execute
        execute_result = GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        @context['type'] == 'root' ? @context['build_path'] : execute_result
      end

      def changed?
        stored_version = @context.stored_version['result']
        repo_version = GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        stored_version != repo_version
      end

    end
  end
end
