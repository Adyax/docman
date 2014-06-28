require 'pathname'

module Docman
  class CreateSymlinkCmd < Docman::Command

    register_command :create_symlink

    def validate_command
      raise "Please provide 'dir' param" if self['target_dir'].nil?
      raise "Please provide 'context'" if @context.nil?
      raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
      raise "Directory #{File.join(@context['docroot_config'].docroot_dir, self['target_dir'])} not exists" unless File.directory? File.join(@context['docroot_config'].docroot_dir, self['target_dir'])
    end

    def execute
      source_path = File.join(@context['docroot_config'].docroot_dir, self['target_dir'])
      Dir.chdir source_path
      source_pathname = Pathname.new source_path
      target_pathname = Pathname.new @context['full_build_path']
      relative_path = target_pathname.relative_path_from source_pathname
      puts `ln -s #{relative_path} #{@context['name']}`
    end
  end
end