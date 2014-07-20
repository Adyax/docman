require 'docman/taggers/tagger'

module Docman
  class IncrementalTagger < Docman::Taggers::Tagger

    register_tagger :incremental

    def execute
      version = self['prev_version'].nil? ? 0 : self['prev_version'].to_i
      version = 0 unless version.is_a? Integer
      version + 1
    rescue
      1
    end

  end
end