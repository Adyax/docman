require 'logger'

module Docman

  module GitUtil

    @logger = Logger.new(STDOUT)
    @git = ENV.has_key?('GIT_CMD') ? ENV['GIT_CMD'] : 'git'

    def self.exec(command, show_result = true)
      @logger.info "#{@git} #{command} in #{Dir.pwd}"
      result = `#{@git} #{command}`
      #result = `#{@git} #{command}`.delete!("\n")
      @logger.info result if show_result and result
      raise "ERROR: #{result}" unless $?.exitstatus == 0
      result
    end

    def self.squash_commits(commit_count, message = nil)
      message = "$(git log --format=%B --reverse HEAD..HEAD@{1})" unless message
      exec "reset --soft HEAD~#{commit_count}"
      exec "commit --no-verify -m \"#{message}\""
    end

    def self.reset_repo(path)
      Dir.chdir path
      exec 'reset --hard'
      exec 'clean -f -d'
    end

    def self.get(repo, path, type, version, single_branch = nil, depth = nil, reset = false)
      FileUtils.rm_rf path if reset and File.directory? path
      if File.directory? path and File.directory?(File.join(path, '.git'))
        Dir.chdir path
        self.reset_repo(path) #if self.repo_changed?(path)
        exec 'fetch --tags'
        if type == 'branch'
          #exec "fetch"
          exec "checkout #{version}"
          exec "pull origin #{version}"
        end
        if type == 'tag'
          exec "checkout tags/#{version}"
        end
      else
        FileUtils.rm_rf path if File.directory? path
        clone_repo(repo, path, type, version, single_branch, depth)
        Dir.chdir path
        exec "checkout #{version}"
      end
      result = type == 'branch' ? self.last_revision(path) : version
      result
    end

    def self.clone_repo(repo, path, type, version, single_branch = nil, depth = nil)
      if type == 'branch'
        single_branch = single_branch ? "-b #{version} --single-branch" : ''
        depth = (depth and depth.is_a? Integer) ? "--depth #{depth}" : ''
      else
        single_branch=''
        depth=''
      end
      exec("clone #{single_branch} #{depth} #{repo} #{path}")
    end

    def self.last_revision(path = nil, branch = 'HEAD')
      result = nil
      if self.repo? path
        Dir.chdir path unless path.nil?
        result = `git rev-parse --short #{branch}`
        result.delete!("\n")
      end
      result
    end

    def self.update(path, options)
      @logger.info "Update #{path} #{options}"
      Dir.chdir path
      exec("pull #{options}")
    end

    def self.commit(root_path, path, message, tag = nil)
      if repo_changed? path
        # pull root_path
        Dir.chdir root_path
        exec %Q(add --all #{path.slice "#{root_path}/"})
        exec %Q(commit --no-verify -m "#{message}") if repo_changed? path
        self.tag(root_path, tag) if tag
        Docman::Application.instance.commit_count = Docman::Application.instance.commit_count + 1
      end
    end

    def self.pull(path, options = nil)
      Dir.chdir path
      exec "pull#{options}"
    end

    def self.branch()
      exec "rev-parse --abbrev-ref HEAD", false
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

    def self.push(root_path, version, no_pull = false)
      Dir.chdir root_path
      exec "pull origin #{version}" unless no_pull
      exec "push origin #{version}"
    end

    def self.tag(root_path, tag)
      Dir.chdir root_path
      exec %Q(tag -a -m "Tagged to #{tag}" "#{tag}")
      exec "push origin #{tag}"
    end
  end

end
