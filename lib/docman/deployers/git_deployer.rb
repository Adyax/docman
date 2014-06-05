module Docman
  module Deployers
    class GitDeployer < Deployer

      register_deployer :git_deployer

      def push(info, state_name)
        version = info['states'][state_name]['version']
        GitUtil.push(info['full_build_path'], version)
      end
    end
  end
end
