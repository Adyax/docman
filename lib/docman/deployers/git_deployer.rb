module Docman
  module Deployers
    class GitDeployer < Deployer

      register_deployer :git_deployer

      def push
        root = @docroot_config.root
        root.state_name = self['state']
        tag = nil

        if self['environment'].has_key?('tagger')
          filepath = File.join(root['full_build_path'], 'VERSION')
          prev_version = File.file?(filepath) ? File.open(filepath) : nil
          params = self['environment']['tagger']
          params['prev_version'] = prev_version
          version = ''
          docman_tag_var = "DOCMAN_TAG"
          if ENV.has_key? docman_tag_var and ENV[docman_tag_var].length > 0
            puts "Variable #{docman_tag_var} => #{ENV[docman_tag_var]}"
            version = ENV[docman_tag_var]
          else
            puts "Variable #{docman_tag_var} not found."
            version = Docman::Taggers::Tagger.create(params, root, self).perform
          end
          File.open(filepath, 'w') {|f| f.write(version) }

          filepath = File.join(root['full_build_path'], 'version.properties')
          File.open(filepath, 'w') {|f| f.write("tag=#{version}") }

          tag = version
        end

        GitUtil.commit(root['full_build_path'], root['full_build_path'], 'Updated version')
        GitUtil.squash_commits(Docman::Application.instance.commit_count, nil, tag)
        GitUtil.push(root['full_build_path'], root.version(type: 'root'))
      end

    end
  end
end
