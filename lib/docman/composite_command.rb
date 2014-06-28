module Docman
  class CompositeCommand < Command
    def initialize(params = nil, context = nil)
      @params = params
      @context = context
      @commands = []
      @log = false
    end

    def add_command(cmd)
      @commands << cmd
    end

    def add_commands(cmds)
      return if cmds.nil?
      cmds.each do |k, v|
        @commands << Docman::Command.create(k, v, @context)
      end
    end

    def execute
      @commands.each { |cmd| cmd.perform }
    end

    def description
      description = ''
      @commands.each { |cmd| description += cmd.description + "\n" }
      description
    end
  end
end