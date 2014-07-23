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

    def self.get(repo, path, type, version, single_branch = nil, depth = nil, reset = false)
      FileUtils.rm_rf path if reset and File.directory? path
      if File.directory? path and File.directory?(File.join(path, '.git'))
        Dir.chdir path
        self.reset_repo(path) #if self.repo_changed?(path)
        if type == 'branch'
          exec "git fetch"
          exec "git checkout #{version}"
          exec "git pull origin #{version}"
        end
        if type == 'tag'
          exec 'git fetch --tags'
          exec "git checkout tags/#{version}"
        end
      else
        FileUtils.rm_rf path if File.directory? path
        if type == 'branch'
          single_branch = single_branch ? "-b #{version} --single-branch" : ''
          depth = (depth and depth.is_a? Integer) ? "--depth #{depth}" : ''
        else
          single_branch=''
          depth=''
        end
        exec "git clone #{single_branch} #{depth} #{repo} #{path}"
        Dir.chdir path
        exec "git checkout #{version}"
      end
      result = type == 'branch' ? self.last_revision(path) : version
      result
    end


    def self.last_revision(path = nil)
      result = nil
      if self.repo? path
        Dir.chdir path unless path.nil?
        result = `git rev-parse --short HEAD`
        result.delete!("\n")
      end
      result
    end

    def self.update(path)
      pull path
    end

    def self.commit(root_path, path, message, tag = nil)
      if repo_changed? path
        # puts message
        pull root_path
        exec %Q(git add --all #{path.slice "#{root_path}/"})
        exec %Q(git commit -m "#{message}") if repo_changed? path
        self.tag(root_path, tag) if tag
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
      exec "git pull origin #{version}"
      exec "git push origin #{version}"
    end

    def self.tag(root_path, tag)
      Dir.chdir root_path
      exec %Q(git tag -a -m "Tagged to #{tag}" "#{tag}")
      exec "git push origin #{tag}"
    end
  end

end