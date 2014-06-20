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

    end
  end
end