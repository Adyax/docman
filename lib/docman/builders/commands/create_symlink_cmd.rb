module Docman
  class CreateSymlinkCmd < Docman::Command

    register_command :create_symlink

    def validate_command
      raise "Please provide 'dir' param" if @params['target_dir'].nil?
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
    end

    def execute
      Dir.chdir File.join(@context['docroot_config'].docroot_dir, @params['target_dir'])
      puts `ln -s #{@context['full_build_path']} #{@context['name']}`
    end
  end
end