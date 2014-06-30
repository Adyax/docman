module Docman
  module Builders
    class GitStripBuilder < Builder

      register_builder :git_strip

      def execute
        FileUtils.rm_r(@context['full_build_path']) if File.directory? @context['full_build_path']
        FileUtils.rm_r @context['temp_path'] if @context.need_rebuild? and File.directory? @context['temp_path']
        result = GitUtil.get(@context['repo'], @context['temp_path'], @context.version_type, @context.version)
        FileUtils.mkdir_p(@context['full_build_path'])
        FileUtils.cp_r(Dir["#{@context['temp_path']}/."], @context['full_build_path'])
        FileUtils.rm_r(File.join(@context['full_build_path'], '.git')) if File.directory?(File.join(@context['full_build_path'], '.git'))
        GitUtil.repo_changed?(@context['full_build_path']) ? result : false
      end

      def changed?
        stored_version = @context.stored_version['result']
        repo_version = GitUtil.get(@context['repo'], @context['temp_path'], @context.version_type, @context.version)
        stored_version != repo_version
      end

    end
  end
end
