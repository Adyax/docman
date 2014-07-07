module Docman
  module Builders
    class GitDirectBuilder < Builder

      register_builder :git_direct_builder

      def execute
        execute_result = GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
        @context['type'] ? @context['build_path'] : execute_result
      end

    end
  end
end
