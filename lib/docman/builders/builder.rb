require 'yaml'
require 'docman/command'

module Docman
  module Builders
    class Builder < Docman::Command
      @@builders = {}

      def self.create(type, params = nil, context = nil)
        c = @@builders[type]
        if c
          c.new(params, context)
        else
          raise "Bad builder type: #{type}"
        end
      end

      def self.register_builder(name)
        @@builders[name] = self
      end

      def execute
        #TODO: need refactoring
        @build_type = @params

        @before_build_actions = Docman::CompositeCommand.new(nil, @context)
        @before_build_actions.add_commands @build_type['before_build_actions']
        @before_build_actions.add_command(Docman::Command.create(:clean_changed, nil, @context))
        @before_build_actions.add_commands @context['before_build_actions'] if @context.has_key? 'before_build_actions'

        @after_build_actions = Docman::CompositeCommand.new(nil, @context)
        @after_build_actions.add_commands @build_type['after_build_actions']
        @after_build_actions.add_commands @context['after_build_actions'] if @context.has_key? 'after_build_actions'

        @before_build_actions.execute
        # Dispatch to corresponding method.
        @context.write_info(self.send("#{@build_type['type']}"))
        @after_build_actions.execute
      end

      def repo?(path)
        File.directory? File.join(path, '.git')
      end

    end
  end
end
