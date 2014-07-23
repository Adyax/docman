module Docman
  module Builders
    class GitDirectBuilder < Builder

      register_builder :git_direct_builder

      def execute
        old_revision = GitUtil.last_revision @context['full_build_path']
        execute_result = GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        # No commit hash for 'root' as it will be changed later
        last_revision = GitUtil.last_revision @context['full_build_path']
        @version = @context['type'] == 'root' ? @context['build_path'] : execute_result
        old_revision != last_revision ? @version : false
      end

      def changed?
        stored_version = @context.stored_version['result']
        # No commit hash for 'root' as it will be changed later
        @version = @context['type'] == 'root' ? @context['build_path'] : GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        stored_version != @version
      end

    end
  end
end
