module Docman
  module Deployers
    class GitDeployer < Deployer

      register_deployer :git_deployer

      def push
        root = @docroot_config.root
        root.state = self['state']
        GitUtil.commit(root['full_build_path'], root['full_build_path'], 'Updated version.yaml')
        GitUtil.push(root['full_build_path'], root.version)
      end

    end
  end
end
