require 'net/sftp'

module Docman

  class SSHTargetChecker < Docman::TargetChecker
    register_checker :ssh

    def execute
      Net::SFTP.start(self['ssh_host'], self['ssh_user']) do |sftp|
        n = 0
        begin
          n+=1
          logger.info "Checking if files deployed, retry ##{n}"
          data = YAML.load sftp.download!(File.join(self['file_path'], @context['docroot_name'] + @context['environment'], self['filename']))
          sleep 30
        end until data['random'] == self['version']
      end
    end

  end
end
