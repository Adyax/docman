module Docman
  module Builders
    class GitDirectBuilder < Builder

      register_builder :git_direct_builder

      def execute
        execute_result = GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        # No commit hash for 'root' as it will be changed later
        @version = @context['type'] == 'root' ? @context['build_path'] : execute_result
        @last_revision != @version ? @version : false
      end

      def changed?
        stored_version = @context.stored_version['result']
        @last_revision = GitUtil.last_revision @context['full_build_path']
        # No commit hash for 'root' as it will be changed later
        @version = @context['type'] == 'root' ? @context['build_path'] : GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        stored_version != @version
      end

    end
  end
end