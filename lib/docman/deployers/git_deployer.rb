module Docman
  module Deployers
    class GitDeployer < Deployer

      register_deployer :git_deployer

      def execute
        GitUtil.push(@context['full_build_path'], @context.version)
      end
    end
  end
end
