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
      add_actions(self, @context)
      add_actions(@context, @context) if @context
    end

    def add_actions(obj, context = nil)
      if obj.has_key? 'hooks' and obj['hooks'].has_key? @type and not obj['hooks'][@type].nil?
        obj['hooks'][@type].each_pair do |name, hooks|
          hooks = Marshal::load(Marshal.dump(hooks))
          unless context.nil? or hooks.nil?
            hooks.each do |hook|
              hook['order'] = 0 unless hook['order']
              hook['context'] = context
            end
          end
          if @hooks[name].nil?
            @hooks[name] = hooks
          else
            @hooks[name].concat(hooks)
          end
        end
      end
    end

    def add_action(name, hook, context = nil)
      hook['order'] = 0 unless hook['order']
      if @hooks.has_key? name
        @hooks[name] << hook
      else
        @hooks[name] = [hook]
      end
    end

    def run_actions(name)
      if @hooks.has_key?(name) and not @hooks[name].nil?
        @hooks[name].sort_by!{|a| a['order']}
        @hooks[name].each do |hook|
          next if hook.has_key?('run_on_success_only') and hook['run_on_success_only'] and not @execute_result
          context = hook.has_key?('context') ? hook['context'] : @context
          Docman::Command.create(hook, context, self).perform
        end
      end
    end

    def run_with_hooks(method)
       with_logging(method) do
        run_actions("before_#{method}")
        run_hook "before_#{method}".to_sym
        result = self.send(method)
        @execute_result = result if method == 'execute'
        run_hook "after_#{method}".to_sym
        run_actions("after_#{method}")
      end
    end

    # @abstract
    def execute
      raise NoMethodError.new("Please define #execute for #{self.class.name}", '')
    end

    def perform
      config if self.respond_to? :config
      validate_command if self.respond_to? :validate_command
      run_with_hooks('execute')
      @execute_result
    rescue CommandValidationError => e
      log "Command validation error: #{e.message}", 'error'
      return false
    rescue NoChangesError => e
      log "No changes: #{e.message}", 'error'
      return false
    rescue StandardError => e
      log e.message, 'error'
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
      value.gsub!('$ROOT$', @context['docroot_config'].root['full_build_path']) unless @context['docroot_config'].root['full_build_path'].nil?
      value.gsub!('$DOCROOT$', @context['docroot_config'].docroot_dir) unless @context['docroot_config'].docroot_dir.nil?
      value.gsub!('$PROJECT$', @context['full_build_path']) unless @context['full_build_path'].nil?
      value.gsub!('$INFO$', @context['full_path']) unless @context['full_path'].nil?
      value.gsub!('$ENVIRONMENT$', @context.environment_name) unless @context.environment_name.nil?
    end

  end
end