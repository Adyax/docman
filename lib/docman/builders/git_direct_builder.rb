module Docman
  module Builders
    class GitDirectBuilder < Builder

      register_builder :git_direct

      def execute
        GitUtil.get(@context['repo'], @context['full_build_path'], @context.version_type, @context.version)
      end

    end
  end
end
