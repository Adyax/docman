require 'docman/taggers/tagger'

module Docman
  class ComponentsTagger < Docman::Taggers::Tagger

    register_tagger :components

    def execute
      tag = ''
      time = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
      state = @caller['state']
      if @caller.docroot_config.structure['root']['type'] == 'root'
        tag_parts = []
        tag_parts << "#{state}--#{time}"
        @caller.build_results.each { |component_name, component_build_result|
          unless component_name == 'master'
            tag_parts << "#{component_name}-#{component_build_result['version']}"
          end
        }
        tag = tag_parts.join('--')
      else
        if @caller.build_results['master']['version_type'] == 'tag'
          tag = "#{state}--#{@caller.build_results['master']['version']}"
        else
          tag = "#{state}--#{time}--#{@caller.build_results['master']['version']}"
        end
      end
      tag_sliced = tag.slice(0, 250).slice(/^(.+)[^a-zA-Z0-9]*$/, 1)
      tag_sliced
    end

  end
end
