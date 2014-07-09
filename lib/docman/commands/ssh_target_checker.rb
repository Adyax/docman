require 'net/sftp'

module Docman

  class SSHTargetChecker < Docman::TargetChecker
    register_checker :ssh

    def execute
      filename = File.join(self['file_path'], @context['docroot_name'] + @context['environment'], self['filename'])
      Net::SFTP.start(self['ssh_host'], self['ssh_user']) do |sftp|
        n = 0
        begin
          n+=1
          log "Checking if files deployed, retry ##{n}, filename: #{filename}"
          sftp.stat!(filename) do |response|
            unless response.ok?
              sleep 15
            end
          end
          data = YAML.load sftp.download!(filename)
          sleep 30
        end until data['random'] == self['version']
      end
      true
    end

  end
end
