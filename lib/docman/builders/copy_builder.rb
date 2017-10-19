require 'pathname'

module Docman
  module Builders
    class CopyBuilder < Builder

      register_builder :copy_builder

      def prepare_build_dir
        if not @context['root_repo'].nil?
          GitUtil.get(@context['root_repo'], @context['full_build_path'], @context.version_type(type: 'root'), @context.version(type: 'root'), true, 1)
        end
      end

      def execute
        prepare_build_dir
        docroot_config_dir = Pathname(@context['docroot_config'].docroot_config_dir)
        config_dir = Pathname(@context['docroot_config'].config_dir)
        log("Copy project files from: #{docroot_config_dir}")
        `rsync -a --exclude '.git' --exclude 'config.json' --exclude '#{config_dir.relative_path_from(docroot_config_dir)}' #{File.join(@context['docroot_config'].docroot_dir, 'config')}/. #{@context['full_build_path']}`
      end

      def version
        @context['build_path']
      end

    end
  end
end
