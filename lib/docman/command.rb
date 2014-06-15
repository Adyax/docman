module Docman
  class Command

    @@subclasses = {}

    def self.create(type, params = nil, context = nil)
      c = @@subclasses[type]
      if c
        c.new(params, context)
      else
        raise "Bad command type: #{type}"
      end
    end

    def self.register_command(name)
      @@subclasses[name] = self
    end

    def initialize(params, context)
      @params = params
      @context = context
    end

    # @abstract
    def execute
      raise NoMethodError.new("Please define #execute for #{self.class.name}", '')
    end

    def validate_command
    end

    def perform
      validate_command
      execute
    end

  end
end