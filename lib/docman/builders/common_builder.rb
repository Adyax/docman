module Docman
  module Builders
    class CommonBuilder < Builder

      register_builder :common

      def dir
        if File.directory? @info['full_build_path']
          FileUtils.rm_r(@info['full_build_path']) if self.repo? @info['full_build_path']
        end
        FileUtils::mkdir_p @info['full_build_path']
        @info['build_path']
      end
    end
  end
end
