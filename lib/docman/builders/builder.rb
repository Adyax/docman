require 'docman/command'

module Docman
  module Builders
    class Builder < Docman::Command
      @@builders = {}
      @@builded = []

      def self.create(params = nil, context = nil)
        c = @@builders[params['handler']]
        if c
          c.new(params, context)
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
        @not_execute = true if @@builded.include? @context['name']
        actions = Docman::CompositeCommand.new(nil, @context)
        actions.add_commands self['before']
        actions.add_command(Docman::Command.create(:clean_changed, nil, @context))
        actions.add_commands @context['before'] if @context.has_key? 'before'
        actions.perform
      end

      def after_execute
        actions = Docman::CompositeCommand.new(nil, @context)
        actions.add_commands self['after']
        actions.add_commands @context['after'] if @context.has_key? 'after'
        actions.perform
        @@builded << @context['name']
        @context.write_info
      end

      def repo?(path)
        File.directory? File.join(path, '.git')
      end

    end
  end
end
