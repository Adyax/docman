require 'docman/logging'

module Docman
  module Context
    include Docman::Logging

    def describe(type = 'short')
      self.class.name
    end
  end
end