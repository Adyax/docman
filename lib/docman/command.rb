module Docman
  class Command < Hash

    @@subclasses = {}
    @not_execute = false

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

    def initialize(params, context = nil)
      unless params.nil?
        params.each_pair do |k, v|
          self[k] = v
        end
      end
      # @params = params
      @context = context
    end

    # @abstract
    def execute
      raise NoMethodError.new("Please define #execute for #{self.class.name}", '')
    end

    def validate_command
    end

    def before_execute
    end

    def after_execute
    end

    def perform
      validate_command
      before_execute
      return if @not_execute
      execute
      after_execute
    end

  end
end