module Docman
  module Builders
    class GitProviderBuilder < ProviderBuilder

      register_builder :git_provider_builder

      def prepare_build_dir
        FileUtils.mkdir_p(@context['full_build_path'])
      end

      def build_with_provider
        docman_ignore_var = "DOCMAN_IGNORE"
        if ENV.has_key? docman_ignore_var and ENV[docman_ignore_var].length > 0
          puts "Variable #{docman_ignore_var} => #{ENV[docman_ignore_var]}. Use ignore workflow."

          ignore = ['.git']
          ignore_value = ENV[docman_ignore_var]
          ignore_array = ignore_value.split(":")
          ignore_array.each do |item|
            ignore.push(item)
          end
          ignore.uniq!

          find_ignore_array = []
          ignore.each do |item|
            find_ignore_array.push("^#{File.join(@context['full_build_path'], item).gsub('.', '\.')}/.*$")
            path = ''
            item.split("/").each do |part|
              path = File.join(path, part)
              find_ignore_array.push("^#{File.join(@context['full_build_path'], path).gsub('.', '\.')}$")
            end
          end
          find_ignore = "-e \"#{find_ignore_array.join("\" -e \"")}\""

          puts "FIND IGNORE => #{find_ignore}"
          `find #{@context['full_build_path']} -mindepth 1 -print0 | grep -z -v #{find_ignore} | xargs -0 -r -t rm -rf` if File.directory? @context['full_build_path']
          FileUtils.rm_r self['target_path'] if @context.need_rebuild? and File.directory? self['target_path']

          result = @provider.perform

          rsync_ignore_array = ignore.each do |item|
            "--exclude \"#{item}\""
          end
          rsync_ignore = "--exclude=\"/#{rsync_ignore_array.join("\" --exclude=\"/")}\""

          puts "RSYNC IGNORE => #{rsync_ignore}"
          `rsync -a #{rsync_ignore} #{self['target_path']}/. #{@context['full_build_path']}`
        else
          puts "Variable #{docman_ignore_var} not found. Use standard workflow."
          `find #{@context['full_build_path']} -mindepth 1 -maxdepth 1 -not -name '.git' -exec rm -rf {} \\;` if File.directory? @context['full_build_path']
          FileUtils.rm_r self['target_path'] if @context.need_rebuild? and File.directory? self['target_path']
          result = @provider.perform
          `rsync -a --exclude '.git' #{self['target_path']}/. #{@context['full_build_path']}`
        end

        result
      end

      def changed_from_last_version?
        @provider.changed_from_last_version?
      end

      def execute
        prepare_build_dir
        @execute_result = build_with_provider
        changed_from_last_version? ? @execute_result : false
      end

    end
  end
end
