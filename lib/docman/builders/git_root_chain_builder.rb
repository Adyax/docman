module Docman
  module Builders
    class GitRootChainBuilder < Builder

      register_builder :git_root_chain_builder

      def execute
        GitUtil.get(@context['root_repo'], @context['full_build_path'], @context.version_type(type: 'root'), @context.version(type: 'root'))
        @version = Docman::Command.create({'type' => :git_copy_repo_content, 'remove_target' => true}, @context, self).perform
        @last_revision != @version ? @version : false
      end

      def changed?
        stored_version = @context.stored_version['result']
        @last_revision = GitUtil.last_revision @context['temp_path']
        # No commit hash for 'root' as it will be changed later
        @version = GitUtil.get(@context['repo'], @context['temp_path'], @context.version_type, @context.version)
        stored_version != @version
      end

    end
  end
end
