require 'net/sftp'

module Docman

  class TargetChecker < Docman::Command
    @@checkers = {}

    def self.create(params = nil, context = nil)
      c = @@checkers[params['handler']]
      if c
        c.new(params, context)
      else
        raise "Bad checker type: #{type}"
      end
    end

    def self.register_checker(name)
      @@checkers[name] = self
    end

  end
end
