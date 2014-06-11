require 'yaml'

module Docman
  module Builders
    class DrupalBuilder < Builder

      register_builder :drupal

      def drush
        return unless @info.need_rebuild?
        puts 'Download drupal through drush'
        FileUtils.mkdir_p(@info['temp_path'])
        Dir.chdir @info['temp_path']
        `drush dl drupal-#{@info.version} --yes`
        FileUtils.mkdir_p(@info['full_build_path'])
        FileUtils.cp_r(Dir["#{@info['temp_path']}/drupal-#{@info.version}/."], @info['full_build_path'])
      end

    end
  end
end
