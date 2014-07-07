module Docman
  module Builders
    class DirBuilder < Builder

      register_builder :dir_builder

      def execute
        if File.directory? @context['full_build_path']
          FileUtils.rm_r(@context['full_build_path']) if GitUtil.repo? @context['full_build_path']
        end
        FileUtils::mkdir_p @context['full_build_path']
        @context['build_path']
      end

    end
  end
end
