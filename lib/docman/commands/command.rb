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

    def initialize(params, context = nil, caller = nil)
      unless params.nil?
        params.each_pair do |k, v|
          self[k] = v
        end
      end
      @context = context
      @caller = caller
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
          logger.debug "#{prefix}Started #{describe}"
        else
          logger.debug "#{prefix}Started #{describe} in Context: #{@context.describe}"
        end
      end

      validate_command
      logger.debug "#{prefix}Before execute start" if @log
      before_execute
      logger.debug "#{prefix}Before execute finish" if @log
      unless @not_execute
        logger.debug "#{prefix}Execute start" if @log
        @execute_result = execute
        logger.debug "#{prefix}Execute finish" if @log
        logger.debug "#{prefix}After execute start" if @log
        after_execute
        logger.debug "#{prefix}After execute finish" if @log
        @execute_result
      end

      logger.debug "Finished #{describe}" if @log

      @execute_result
    end

    def describe(type = 'short')
      "Command: #{properties_info}"
    end

    def prefix
      "#{self.class.name}: "
    end

  end
end