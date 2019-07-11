module Docman
  module Builders
    class GitProviderBuilder < ProviderBuilder

      register_builder :git_provider_builder

      def prepare_build_dir
        FileUtils.mkdir_p(@context['full_build_path'])
      end

      def build_with_provider
        ignore = ['.git']
        docman_ignore_var = "DOCMAN_IGNORE"
        if ENV.has_key? docman_ignore_var and ENV[docman_ignore_var].length > 0
          puts "Variable #{docman_ignore_var} => #{ENV[docman_ignore_var]}"
          is = ENV[docman_ignore_var]
          isa = is.split(":")
          isa.each do |item|
            ignore.push(item)
          end
        else
          puts "Variable #{docman_ignore_var} not found."
        end
        ignore.uniq!

        fia = []
        ignore.each do |item|
          path = ''
          item.split("/").each do |part|
            path = [path, part].join("/")
            fia.push(path)
          end
        end

        find_ignore = "\\( -path \"./#{fia.join("\" -o -path \"./")}\" \\)"

        puts "FIND IGNORE => #{find_ignore}"

        `find #{@context['full_build_path']} -mindepth 1 #{find_ignore} -prune -o -print0 | xargs -0 -r -t rm -rf` if File.directory? @context['full_build_path']
        FileUtils.rm_r self['target_path'] if @context.need_rebuild? and File.directory? self['target_path']
        result = @provider.perform

        ria = ignore.each do |item|
          "--exclude \"#{item}\""
        end
        rsync_ignore = "--exclude=\"#{ria.join("\" --exclude=\"")}\""

        puts "RSYNC IGNORE => #{rsync_ignore}"

        `rsync -a #{rsync_ignore} #{self['target_path']}/. #{@context['full_build_path']}`
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
