require 'docman/logging'

module Docman


  class Command < Hash

    include Docman::Logging

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
      @log = true
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
      if @log
        if @context.nil?
          logger.info "Performing command: #{describe}"
        else
          logger.info "Performing command: #{describe} in Context: #{@context.describe}"
        end
      end
      validate_command
      before_execute
      return if @not_execute
      @execute_result = execute
      after_execute
      @execute_result
    end

    def describe(type = 'short')
      properties_info
    end

  end
end