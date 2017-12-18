require 'docman/taggers/tagger'

module Docman
  class SourceTagger < Docman::Taggers::Tagger

    register_tagger :source

    def execute
      if @caller.build_results['master']['version_type'] == 'tag'
        @caller.build_results['master']['version']
      end
    end

  end
end