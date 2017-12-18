module Docman
  module Taggers
    class Tagger < Docman::Command

      @@taggers = {}

      #todo: docroot config in separate repos for projects

      def self.create(params, context = nil, caller = nil)
        c = @@taggers[params['handler']]
        if c
          c.new(params, context, caller, 'tagger')
        else
          raise "Bad tagger type: #{params['handler']}"
        end
      end

      def self.register_tagger(name)
        @@taggers[name] = self
      end

      def initialize(params, context = nil, caller = nil, type = nil)
        super(params, context, caller, type)
      end

    end
  end
end