require 'docman/logging'
require 'docman/exceptions/command_validation_error'
require 'docman/exceptions/no_changes_error'
require 'hooks'

module Docman

  class Command < Hash

    include Hooks
    include Docman::Logging

    attr_reader :type

    @@subclasses = {}

    define_hooks :before_execute, :after_execute

    def self.create(params, context = nil, caller = nil)
      c = @@subclasses[params['type']]
      if c
        c.new(params, context, caller)
      else
        raise "Bad command type: #{params['type']}"
      end
    end

    def self.register_command(name)
      @@subclasses[name] = self
    end

    def initialize(params = nil, context = nil, caller = nil, type = 'command')
      unless params.nil?
        params.each_pair do |k, v|
          self[k] = v
        end
      end
      @context = context
      @caller = caller
      @type = type
      @log = self.has_key?('log') ? self['log'] : true
      @hooks = {}
    end

    def config
      add_actions self
      add_actions @context unless @context.nil?
    end

    def add_actions(obj)
      if obj.has_key? 'hooks' and obj['hooks'].has_key? @type
        obj['hooks'][@type].each_pair do |name, hook|
          if @hooks[name].nil?
            @hooks[name] = hook
          else
            @hooks[name].concat(hook)
          end
        end
      end
    end

    def add_action(name, hook)
      if @hooks.has_key? name
        @hooks[name] << {'type' => hook}
      else
        @hooks[name] = [hook]
      end
    end

    def run_actions(name)
      if @hooks.has_key? name
        @hooks[name].each do |hook|
          Docman::Command.create(hook, @context, self).perform
        end
      end
    end

    def run_with_hooks(method)
       with_logging(method) do
        run_hook "before_#{method}".to_sym
        result = self.send(method)
        @execute_result = result if method == 'execute'
        run_hook "after_#{method}".to_sym
      end
    end

    before_execute do
      run_actions('before_execute')
    end

    # @abstract
    def execute
      raise NoMethodError.new("Please define #execute for #{self.class.name}", '')
    end

    after_execute do
      run_actions('after_execute')
    end

    def perform
      config if self.respond_to? :config
      validate_command if self.respond_to? :validate_command
      @execute_result = run_with_hooks('execute')
    rescue CommandValidationError => e
      logger.error "Command validation error: #{e.message}"
      return false
    rescue NoChangesError => e
      logger.info "No changes: #{e.message}"
      return false
    rescue StandardError => e
      logger.error e.message
      raise
    ensure
      @execute_result
    end

    def describe(type = 'short')
      "Command: #{properties_info}"
    end

    def prefix
      prefix = []
      prefix << @caller.prefix if not @caller.nil? and @caller.respond_to? :prefix
      prefix << self.class.name
      prefix.join(' - ')
    end

    def replace_placeholder(value)
      value.gsub! '$ROOT$', @context['docroot_config'].root['full_build_path']
      value.gsub! '$DOCROOT$', @context['docroot_config'].docroot_dir
      value.gsub! '$PROJECT$', @context['full_build_path']
      value.gsub! '$INFO$', @context['full_path']
      value.gsub! '$ENVIRONMENT$', @context['docroot_config'].deploy_target['environment']
    end

  end
end