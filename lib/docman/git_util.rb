require 'logger'

module Docman

  module GitUtil

    @logger = Logger.new(STDOUT)

    def self.exec(command)
      @logger.info command
      result = `#{command}`.delete!("\n")
      @logger.info result if result
      raise "ERROR: #{result}" unless $?.exitstatus == 0
      result
    end

    def self.reset_repo(path)
      Dir.chdir path
      exec 'git reset --hard'
      exec 'git clean -f -d'
    end

    def self.get(repo, path, type, version, force_return = false)
      if File.directory? path and File.directory?(File.join(path, '.git'))
        Dir.chdir path

        self.reset_repo(path) #if self.repo_changed?(path)

        if type == 'branch'
          exec "git checkout #{version}"
          initial_revision = self.last_revision
          exec "git pull origin #{version}"
        end
        if type == 'tag'
          exec 'git fetch --tags'
          initial_revision = self.last_revision
          exec "git checkout tags/#{version}"
        end
      else
        initial_revision = nil
        FileUtils.rm_rf path if File.directory? path
        exec "git clone #{repo} #{path}"
        Dir.chdir path
        exec "git checkout #{version}"
      end
      result = self.last_revision
      @logger.info "Commit hash: #{result}"
      # force_return or result != initial_revision ? result : false
      result
    end

    def self.last_revision
      result = `git rev-parse --short HEAD`
      result.delete!("\n")
    end

    def self.update(path)
      pull path
    end

    def self.commit(root_path, path, message)
      if repo_changed? path
        # puts message
        pull root_path
        exec %Q(git add --all #{path.slice "#{root_path}/"})
        exec %Q(git commit -m "#{message}") if repo_changed? path
      end
    end

    def self.pull(path)
      Dir.chdir path
      exec 'git pull'
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