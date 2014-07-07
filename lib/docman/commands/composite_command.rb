module Docman
  class CompositeCommand
    def initialize(caller = nil)
      @caller = caller
      @commands = []
    end

    def add_command(cmd)
      @commands << cmd
    end

    def add_commands(cmds, context = nil)
      return if cmds.nil?
      cmds.each do |k, v|
        @commands << Docman::Command.create(k, v, context)
      end
    end

    def perform
      @commands.each { |cmd| cmd.perform }
    end

    def has_commands?
      @commands.any?
    end

  end
end