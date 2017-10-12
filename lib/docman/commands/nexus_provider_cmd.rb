module Docman
  class NexusProvider < Docman::Command

    register_command :nexus_provider

    def validate_command
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
      raise "Please provide 'artifact_aid'" if @context['artifact_aid'].nil?
      raise "Please provide 'artifact_gid'" if @context['artifact_gid'].nil?
      raise "Please provide 'artifact_version'" if @context['artifact_version'].nil?
    end

    def execute
      # TODO: refactor it.
      nexus_address = '138.68.81.158:8081'
      a = @context['artifact_aid']
      g = @context['artifact_gid']
      v = @context['artifact_version']
      r = 'releases'
      e = 'tar.gz'
      artifact_file = "#{a}-#{v}.#{e}"

      @context['version_type'] = 'nexus_artifact'
      @context['version'] = v

      FileUtils.mkdir_p(self['target_path'])
      Dir.chdir self['target_path']

      # TODO: refactor cmd execution.
      cmd = "wget -O #{artifact_file} \"http://#{nexus_address}/nexus/service/local/artifact/maven/content?a=#{a}&g=#{g}&v=#{v}&r=#{r}&e=#{e}\""

      `#{cmd}`

      if $?.exitstatus > 0
        raise "Artifact retrieving has been failed: #{cmd}"
      end

      cmd ="tar --strip-components=1 -xzf #{artifact_file}"
      `#{cmd}`

      if $?.exitstatus > 0
        raise "Artifact unpack has been failed: #{cmd}"
      end

      cmd ="rm -f #{artifact_file}"
      `#{cmd}`
      @execute_result = artifact_file
    end

    def changed?
      true
    end

    def changed_from_last_version?
      true
    end

  end
end