module Docman
  module Builders
    class SymlinkBuilder < Builder

      register_builder :symlink_builder

      def execute
        if File.directory? @context['full_build_path']
          log("Removed dir: #{@context['full_build_path']} because directory is a directory")
          FileUtils.rm_r(@context['full_build_path'])
        end
        Dir.chdir Pathname(@context['full_build_path']).dirname
        `ln -f -s #{@context['target_path']} #{@context['name']}`
        log("Created symlink: #{@context['full_build_path']}")
        @context['build_path']
      end

      def version
        @context['build_path']
      end

    end
  end
end
