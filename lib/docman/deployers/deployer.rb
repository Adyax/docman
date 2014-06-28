require 'docman/commands/target_checker'
require 'docman/commands/ssh_target_checker'

module Docman
  module Deployers
    class Deployer < Docman::Command

      @@deployers = {}

      def self.create(params, context)
        c = @@deployers[params['handler']]
        if c
          c.new(params, context)
        else
          raise "Bad deployer type: #{type}"
        end
      end

      def self.register_deployer(name)
        @@deployers[name] = self
      end

      def initialize(params, context)
        super(params, context)
        @docroot_config = context.docroot_config
        @builded = []
      end

      def before_execute
        super
      end

      def execute
        if self['name'].nil?
          build_recursive
        else
          build_dir_chain(@docroot_config.info_by(self['name']))
        end

        push
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
        Docman::Builders::Builder.create(self['builders'][info['type']], info).perform
        @builded << info['name']
      end


      def build_recursive(info = nil)
        info = info ? info : @docroot_config.structure
        build_dir(info)

        info['children'].each do |child|
          build_recursive(child)
        end
      end

      def after_execute
        super
        files_deployed?
      end

      def files_deployed?
        target_checker = Docman::TargetChecker.create(self['target_checker'], nil).perform
        test=''
      end

      def describe(type = 'short')
        properties_info([:handler])
      end

    end
  end
end