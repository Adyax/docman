require 'net/sftp'

module Docman

  class SSHTargetChecker < Docman::TargetChecker
    register_checker :ssh

    def execute
      Net::SFTP.start(self['ssh_host'], self['ssh_user']) do |sftp|
      # grab data off the remote host directly to a buffer
      #data = sftp.download!("/path/to/remote")
      end
    end

  end
end
