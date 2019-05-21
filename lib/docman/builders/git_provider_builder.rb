module Docman
  module Builders
    class GitProviderBuilder < ProviderBuilder

      register_builder :git_provider_builder

      def prepare_build_dir
        FileUtils.mkdir_p(@context['full_build_path'])
      end

      def build_with_provider
        `find #{@context['full_build_path']} -mindepth 1 -maxdepth 1 -not -name '.git' -exec rm -rf {} \\;` if File.directory? @context['full_build_path']
        FileUtils.rm_r self['target_path'] if @context.need_rebuild? and File.directory? self['target_path']
        result = @provider.perform
        `rsync -a --exclude '.git' #{self['target_path']}/. #{@context['full_build_path']}`
        result
      end

      def changed_from_last_version?
        @provider.changed_from_last_version?
      end

      def execute
        prepare_build_dir
        @execute_result = build_with_provider
        changed_from_last_version? ? @execute_result : false
      end

    end
  end
end
