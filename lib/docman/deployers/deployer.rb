require 'docman/commands/target_checker'
require 'docman/commands/ssh_target_checker'
require 'docman/exceptions/no_changes_error'
require 'securerandom'

module Docman
  module Deployers
    class Deployer < Docman::Command

      attr_accessor :before, :after

      define_hooks :before_push, :after_push

      @@deployers = {}

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
      end

      def config
        unless self['name'].nil?
          @docroot_config.chain(@docroot_config.info_by(self['name'])).values.each do |info|
            add_actions(info)
          end
        end
      end

      before_execute do
        stored_config_hash = read_version_file_param('config_hash')
        @config_hash = Docman::Application.instance.config.config_hash
        stored_docroot_config_hash = read_version_file_param('docroot_config_hash')
        @docroot_config_hash = @docroot_config.config_hash
        # config = Docman::Application.instance.config
        # log(config.to_yaml)
        if stored_config_hash != @config_hash or stored_docroot_config_hash != @docroot_config_hash
          logger.info 'Forced rebuild as configuration was changed'
          Docman::Application.instance.force = true
        end
      end

      def execute
        logger.info "Deploy started"
        if self['name'].nil?
          build_recursive
        else
          build_dir_chain(@docroot_config.info_by(self['name']))
        end

        if @changed
          filename = 'version.yaml'
          path = File.join(@docroot_config.root['full_build_path'], filename)
          version = SecureRandom.hex
          write_version_file version, path
          run_with_hooks('push')
          raise 'Files are not deployed' unless files_deployed? version, filename
        else
          logger.info 'No changes in docroot'
        end
        logger.debug 'Deploy results:'
        logger.debug @build_results.to_yaml
        logger.info 'Deploy finished'
      end

      def read_version_file_param(param)
        path = File.join(@docroot_config.root['full_build_path'], 'version.yaml')
        return false unless File.file?(path)
        content = YAML::load_file(path)
        content[param] if content.has_key? param
      end

      def write_version_file(version, path)
        to_write = Hash.new
        to_write['random'] = version
        # config = Docman::Application.instance.config.raw_config
        # log(config.to_yaml)
        to_write['config_hash'] = @config_hash
        to_write['docroot_config_hash'] = @docroot_config_hash
        File.open(path, 'w') {|f| f.write to_write.to_yaml}
      end

      def build_dir_chain(info)
        @docroot_config.chain(info).values.each do |item|
          item.state = self['state']
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
        info.state = self['state']

        build_result = Docman::Builders::Builder.create(self['builders'][info['type']], info, self).perform
        logger.info '-------------------------------------------------------'
        @changed = true if build_result
        @build_results[info['name']] = build_result

        @builded << info['name']
      end

      def build_recursive(info = nil)
        info = info ? info : @docroot_config.structure
        build_dir(info)

        info['children'].each do |child|
          build_recursive(child)
        end
      end

      def files_deployed?(version, filename)
        return true unless self.has_key? 'target_checker'
        params = self['target_checker']
        params['version'] = version
        params['filename'] = filename
        Docman::TargetChecker.create(params, self).perform
      end

      def describe(type = 'short')
        properties_info(['handler'])
      end

    end
  end
end