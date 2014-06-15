module Docman
  module Deployers
    class Deployer

      attr_reader :deploy_target

      @@subclasses = {}

      def self.create(type, deploy_target)
        c = @@subclasses[type]
        if c
          c.new(deploy_target)
        else
          raise "Bad deployer type: #{type}"
        end
      end

      def self.register_deployer(name)
        @@subclasses[name] = self
      end

      def initialize(deploy_target)
        @deployed = []
        @deploy_target = deploy_target
      end

      def build(info)
        return if @deployed.include? info['name']
        build_type = build_type(info['type'])
        Docman::Builders::Builder.create(build_type['handler'], build_type, info).execute()
        @deployed << info['name']
      end

      def build_type(type)
        @deploy_target['builders'][type]
      end

    end
  end
end