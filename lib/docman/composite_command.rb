module Docman
  class CompositeCommand < Command
    def initialize(params = nil, context = nil)
      @params = params
      @context = context
      @commands = []
    end

    def add_command(cmd)
      @commands << cmd
    end

    def add_commands(cmds)
      return if cmds.nil?
      cmds.each do |k, v|
        Docman::Command.create(k, v, @context).perform
      end
    end

    def execute
      @commands.each { |cmd| cmd.execute }
    end

    def description
      description = ''
      @commands.each { |cmd| description += cmd.description + "\n" }
      description
    end
  end
end