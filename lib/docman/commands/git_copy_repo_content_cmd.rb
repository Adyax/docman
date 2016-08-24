module Docman
  class GitCopyRepoContent < Docman::Command

    register_command :git_copy_repo_content

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
    end

    def execute
      if (self['remove_target'])
        FileUtils.rm_r(Dir["#{@context['full_build_path']}/*"]) if File.directory? @context['full_build_path']
      end
      FileUtils.rm_r @context['temp_path'] if @context.need_rebuild? and File.directory? @context['temp_path']
      @version = GitUtil.get(@context['repo'], @context['temp_path'], @context.version_type, @context.version, nil, nil)
      # FileUtils.rm_r(File.join(@context['temp_path'], '.git')) if File.directory?(File.join(@context['temp_path'], '.git'))
      FileUtils.mkdir_p(@context['full_build_path'])
      `rsync -a --exclude '.git' #{@context['temp_path']}/. #{@context['full_build_path']}`
      @version
    end
  end
end