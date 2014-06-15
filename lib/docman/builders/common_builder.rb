module Docman
  module Builders
    class CommonBuilder < Builder

      register_builder :common

      def dir
        if File.directory? @context['full_build_path']
          FileUtils.rm_r(@context['full_build_path']) if self.repo? @context['full_build_path']
        end
        FileUtils::mkdir_p @context['full_build_path']
        @context['build_path']
      end
    end
  end
end
