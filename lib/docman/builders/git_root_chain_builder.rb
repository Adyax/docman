module Docman
  module Builders
    class GitRootChainBuilder < GitProviderBuilder

      register_builder :git_root_chain_builder

      def prepare_build_dir
        GitUtil.get(@context['root_repo'], @context['full_build_path'], @context.version_type(type: 'root'), @context.version(type: 'root'))
      end

    end
  end
end
