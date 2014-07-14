require 'net/sftp'

module Docman

  class SSHTargetChecker < Docman::TargetChecker
    register_checker :ssh

    def execute
      filename = File.join(self['file_path'], self['filename'])
      Net::SFTP.start(self['ssh_host'], self['ssh_user']) do |sftp|
        n = 0
        begin
          sleep 15
          n+=1
          log "Checking if files deployed, retry ##{n}, filename: #{filename}"
          sftp.stat!(filename) do |response|
            unless response.ok?
              sleep 15
            end
          end
          data = YAML.load sftp.download!(filename)
        end until data['random'] == self['version']
      end
      true
    end

  end
end
