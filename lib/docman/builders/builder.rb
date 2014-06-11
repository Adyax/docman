require 'yaml'

module Docman
  module Builders
    class Builder
      @@subclasses = {}

      def self.create(type, root, build_type, info)
        c = @@subclasses[type]
        if c
          c.new(root, build_type, info)
        else
          raise "Bad builder type: #{type}"
        end
      end

      def self.register_builder(name)
        @@subclasses[name] = self
      end

      def initialize(root, build_type, info)
        @root = root
        @build_type = build_type
        @info = info
        @before_build_actions = @build_type['before_build_actions'].nil? ? [] : @build_type['before_build_actions']
        @after_build_actions = @build_type['after_build_actions'].nil? ? [] : @build_type['after_build_actions']
        @before_build_actions << 'clean_if_changed'
        @after_build_actions << 'apply_scripts'
      end

      def before_build_action_clean_if_changed
        if File.directory? @info['full_build_path']
          FileUtils.rm_r @info['full_build_path'] if @info.need_rebuild?
        end
      end

      def after_build_action_apply_scripts
        if @info.has_key? 'after_build'
          @info['after_build'].each do |k, v|
            Dir.chdir File.join(@info['docroot_config'].docroot_dir, v['dir']) if v.has_key? 'dir'
            puts `#{File.join(@info['full_path'], v['name'])}` if v['type'] == 'script' and v.has_key? 'name' and
                File.file?(File.join(@info['full_path'], v['name']))
          end
        end
      end

      def do
        perform(@before_build_actions, 'before_build_action')
        # Dispatch to corresponding method.
        @info.write_info(self.send("#{@build_type['type']}"))
        perform(@after_build_actions, 'after_build_action')
      end

      def perform(actions, method_prefix)
        unless actions.nil?
          actions.each do |action|
            method = "#{method_prefix}_#{action}"
            self.send(method)
          end
        end
      end

      def repo?(path)
        File.directory? File.join(path, '.git')
      end

      def after_build_action_git_commit
        message = "name: #{@info['name']} updated, state: #{@info['state']}"
        GitUtil.commit(@root['full_build_path'], @info['full_build_path'], message)
      end
    end
  end
end
