module Docman
  module Builders
    class GitStripBuilder < GitProviderBuilder

      register_builder :git_strip_builder

      def changed_from_last_version?
        GitUtil.repo_changed?(@context['full_build_path'])
      end

    end
  end
end
