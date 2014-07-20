module Docman
  module Builders
    class DirBuilder < Builder

      register_builder :dir_builder

      def execute
        if File.directory? @context['full_build_path']
          if GitUtil.repo? @context['full_build_path']
            log("Removed dir: #{@context['full_build_path']} because directory is git repo")
            FileUtils.rm_r(@context['full_build_path'])
          end
        end
        log("Created dir: #{@context['full_build_path']}")
        FileUtils::mkdir_p @context['full_build_path']
        @context['build_path']
      end

      def version
        @context['build_path']
      end

    end
  end
end
