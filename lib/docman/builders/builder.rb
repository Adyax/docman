require 'docman/commands/command'

module Docman
  module Builders
    class Builder < Docman::Command
      @@builders = {}
      @@build_results = {}

      def self.create(params = nil, context = nil, caller = nil)
        c = @@builders[params['handler']]
        if c
          c.new(params, context, caller)
        else
          raise "Bad builder type: #{type}"
        end
      end

      def self.register_builder(name)
        @@builders[name] = self
      end

      def validate_command
        raise "Please provide 'context'" if @context.nil?
        raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
      end

      def before_execute
        actions = Docman::CompositeCommand.new(nil, @context)
        actions.add_commands self['before']
        actions.add_command(Docman::Command.create(:clean_changed, nil, @context))
        actions.add_commands @context['before'] if @context.has_key? 'before'
        actions.perform
        unless @context.need_rebuild?
          unless changed?
            logger.info "This version already deployed"
            @not_execute = true
          end
        end
      end

      def after_execute
        actions = Docman::CompositeCommand.new(nil, @context)
        actions.add_commands self['after']
        actions.add_commands @context['after'] if @context.has_key? 'after'
        actions.perform
        after_deploy_commands = @context['after_deploy'] if @context.has_key? 'after_deploy'
        @caller.after.add_commands(after_deploy_commands, @context)
        @execute_result = @context.write_info(@execute_result)
      end

      def changed?
        false
      end

      def describe
        "Build: #{properties_info}"
      end

      def prefix
        "#{@context['name']} - #{self.class.name}: "
      end

    end
  end
end
