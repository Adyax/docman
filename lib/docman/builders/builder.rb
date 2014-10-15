require 'docman/commands/command'

module Docman
  module Builders
    class Builder < Docman::Command
      @@builders = {}
      @@build_results = {}


      def self.create(params = nil, context = nil, caller = nil)
        c = @@builders[params['handler']]
        if c
          c.new(params, context, caller, 'builder')
        else
          raise "Bad builder type: #{type}"
        end
      end

      def self.register_builder(name)
        @@builders[name] = self
      end

      def config
        super
        @version = nil
        add_action('before_execute', {'type' => :clean_changed}, @context)
      end

      def validate_command
        raise "Please provide 'context'" if @context.nil?
        raise "Context should be of type 'Info'" unless @context.is_a? Docman::Info
      end

      def version
        @version
      end

      before_execute do
        if @context.need_rebuild?
          @context.build_mode = :rebuild
        else
          if @context.changed? or changed?
            @context.build_mode = :update
            log("Changed")
          else
            log("Not changed")
            @context.build_mode = :none
            raise NoChangesError, 'This version already deployed'
          end
        end

      end

      after_execute do
        if @execute_result
          @execute_result = @context.write_info(@execute_result)
        end
      end

      def changed?
        false
      end

      def describe
        "Build: #{properties_info}"
      end

      def prefix
        "#{@context['name']} - #{self.class.name}"
      end

    end
  end
end