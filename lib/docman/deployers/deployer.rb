require 'docman/commands/target_checker'
require 'docman/commands/ssh_target_checker'
require 'docman/exceptions/no_changes_error'
require 'securerandom'
require 'diffy'

module Docman
  module Deployers
    class Deployer < Docman::Command

      define_hooks :before_push, :after_push, :before_build, :after_build, :before_deploy, :after_deploy

      @@deployers = {}

      #todo: docroot config in separate repos for projects

      def self.create(params, context = nil, caller = nil)
        c = @@deployers[params['handler']]
        if c
          c.new(params, context, caller, 'deployer')
        else
          raise "Bad deployer type: #{type}"
        end
      end

      def self.register_deployer(name)
        @@deployers[name] = self
      end

      def initialize(params, context = nil, caller = nil, type = nil)
        super(params, context, caller, type)
        @docroot_config = caller.docroot_config
        @builded = []
        @build_results = {}
        @versions = {}
      end

      def config
        unless self['name'].nil?
          @docroot_config.chain(@docroot_config.info_by(self['name'])).values.each do |info|
            add_actions(info, info)
          end
        else
          # add_actions()
        end

        path = @docroot_config.root['full_build_path']
        if File.directory?(path) and GitUtil.repo?(path)
          Dir.chdir path
          if GitUtil.repo_changed? path
            GitUtil.reset_repo path
          end
        end

        stored_config_hash = read_version_file_param('config_hash')
        @config_hash = Docman::Application.instance.config.config_hash
        @config_yaml = Docman::Application.instance.config.unmutable_config.to_yaml

        #TODO: need to refactor
        stored_docroot_config_hash = read_version_file_param('docroot_config_hash')
        @docroot_config_hash = @docroot_config.config_hash
        @docroot_config_yaml = @docroot_config.raw_infos.to_yaml
        if stored_config_hash != @config_hash
          log 'Forced rebuild as configuration was changed', 'info'
          filename = File.join(@docroot_config.root['full_build_path'], 'config.yaml')
          log Diffy::Diff.new(read_file(filename), @config_yaml) if File.file? filename
          Docman::Application.instance.force = true
        end
        if stored_docroot_config_hash != @docroot_config_hash
          log 'Forced rebuild as docroot configuration was changed', 'info'
          filename = File.join(@docroot_config.root['full_build_path'], 'docroot_config.yaml')
          log Diffy::Diff.new(read_file(filename), @docroot_config_yaml) if File.file? filename
          Docman::Application.instance.force = true
        end
      end

      def execute
        run_with_hooks('build')
        if @changed
          run_with_hooks('deploy')
        else
          log 'No changes in docroot', 'info'
        end
        log "Deploy results:\n" + @build_results.to_yaml
      end

      def deploy
        filename = 'version.yaml'
        path = File.join(@docroot_config.root['full_build_path'], filename)
        version = SecureRandom.hex
        write_version_file version, path
        write_config_file @config_yaml, File.join(@docroot_config.root['full_build_path'], 'config.yaml')
        write_config_file @docroot_config_yaml, File.join(@docroot_config.root['full_build_path'], 'docroot_config.yaml')
        run_with_hooks('push')
        raise 'Files are not deployed' unless files_deployed? version, filename
      end

      def files_deployed?(version, filename)
        return true unless self['environment'].has_key? 'target_checker'
        params = self['environment']['target_checker']
        params['version'] = version
        params['filename'] = filename
        Docman::TargetChecker.create(params, self).perform
      end

      def read_file(path)
        YAML::load_file(path)
      rescue
        log "Error in config file #{path}"
        return false
      end

      def read_version_file_param(param)
        path = File.join(@docroot_config.root['full_build_path'], 'version.yaml')
        return false unless File.file?(path)
        content = read_file(path)
        content[param] if content.has_key? param
      end

      def write_version_file(version, path)
        to_write = Hash.new
        to_write['random'] = version
        to_write['config_hash'] = @config_hash
        to_write['docroot_config_hash'] = @docroot_config_hash
        to_write.deep_merge! @versions
        File.open(path, 'w') {|f| f.write to_write.to_yaml}
      end

      def write_config_file(config, path)
        File.open(path, 'w') {|f| f.write config}
      end

      def build
        if self['name'].nil?
          build_recursive
        else
          build_dir_chain(@docroot_config.info_by(self['name']))
        end
      end

      def build_dir_chain(info)
        @docroot_config.chain(info).values.each do |item|
          item.state_name = self['state']
          if item.need_rebuild?
            build_recursive(item)
            return
          elsif
          build_dir(item)
          end
        end
      end

      def build_dir(info)
        return if @builded.include? info['name']
        info.state_name = self['state']
        builder = Docman::Builders::Builder.create(self['builders'][info['type']], info, self)
        build_result = builder.perform
        logger.info '-------------------------------------------------------'
        @changed = true if build_result
        @build_results[info['name']] = build_result ? build_result : 'Not builded'
        @versions[info['name']] = builder.version
        @builded << info['name']
      end

      def build_recursive(info = nil)
        info = info ? info : @docroot_config.structure
        build_dir(info)

        info['children'].each do |child|
          build_recursive(child)
        end
      end

      # TODO: need to refactor.
      def describe(type = 'short')
        properties_info(['handler'])
      end

    end
  end
end