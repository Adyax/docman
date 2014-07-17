require 'yaml'

module Docman
  module Builders
    class DrupalDrushBuilder < Builder

      register_builder :drupal_drush_builder

      def execute
        return if @build_mode == :none
        #return unless @context.need_rebuild?
        puts 'Download drupal through drush'
        FileUtils.mkdir_p(@context['temp_path'])
        Dir.chdir @context['temp_path']
        `drush dl drupal-#{@context.version} --yes`
        FileUtils.mkdir_p(@context['full_build_path'])
        FileUtils.cp_r(Dir["#{@context['temp_path']}/drupal-#{@context.version}/."], @context['full_build_path'])
        @context.version
      end

    end
  end
end
