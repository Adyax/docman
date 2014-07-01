require 'logger'

module Docman

  module GitUtil

    @logger = Logger.new(STDOUT)

    def self.exec(command)
      @logger.info command
      @logger.info `#{command}`
    end

    def self.get(repo, path, type, version)
      if File.directory? path and File.directory?(File.join(path, '.git'))
        Dir.chdir path
        if type == 'branch'
          exec "git checkout #{version}"
          exec "git pull origin #{version}"
        end
        if type == 'tag'
          exec "git fetch --tags"
          exec "git checkout tags/#{version}"
        end
      else
        exec "git clone #{repo} #{path}"
        Dir.chdir path
        exec "git checkout #{version}"
      end
      result = `git rev-parse --short HEAD`
      @logger.info "Commit hash: #{result}"
      result.delete!("\n")
    end

    def self.update(path)
      Dir.chdir path
      exec "git pull"
    end

    def self.commit(root_path, path, message)
      if self.repo_changed? path
        puts message
        Dir.chdir root_path
        `git pull`
        `git add --all #{path.slice "#{root_path}/"}`
        `git commit -m "#{message}"`
      end
    end

    def self.repo?(path)
      File.directory? File.join(path, '.git')
    end

    def self.repo_changed?(path)
      not Exec.do "#{Application::bin}/dm_repo_clean.sh #{path}"
    end

    def self.last_commit_hash(path, branch)
      Dir.chdir path
      result = `git rev-parse --short origin/#{branch}`
      result.delete!("\n")
    end

    def self.push(root_path, version)
      Dir.chdir root_path
      `git pull origin #{version}`
      `git push origin #{version}`
    end
  end

end