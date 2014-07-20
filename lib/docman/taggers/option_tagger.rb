require 'docman/taggers/tagger'

module Docman
  class OptionTagger < Docman::Taggers::Tagger

    register_tagger :option

    def execute
      @caller['tag']
    end

  end
end