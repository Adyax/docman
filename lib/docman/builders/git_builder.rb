require 'yaml'

module Docman
  module Builders
    class DrupalBuilder < Builder

      register_builder :git

      def direct
        puts 'Do direct'
        GitUtil.get(@info['repo'], @info['full_build_path'], @info.version_type, @info.version)
      end

      def strip
        puts 'Do strip'
        FileUtils.rm_r(@info['full_build_path']) if File.directory? @info['full_build_path']
        FileUtils.rm_r @info['temp_path'] if @info.need_rebuild? and File.directory? @info['temp_path']
        result = GitUtil.get(@info['repo'], @info['temp_path'], @info.version_type, @info.version)
        FileUtils.mkdir_p(@info['full_build_path'])
        FileUtils.cp_r(Dir["#{@info['temp_path']}/."], @info['full_build_path'])
        FileUtils.rm_r(File.join(@info['full_build_path'], '.git')) if File.directory?(File.join(@info['full_build_path'], '.git'))
        result
      end

    end
  end
end
