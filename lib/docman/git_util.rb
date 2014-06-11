module Docman

  class GitUtil

    def self.get(repo, path, type, version)
      if File.directory? path and File.directory?(File.join(path, '.git'))
        Dir.chdir path
        `git checkout #{version} && git pull origin #{version}` if type == 'branch'
        if type == 'tag'
          `git fetch --tags`
          `git checkout "tags/#{version}"`
        end
      else
        `git clone #{repo} #{path}`
        Dir.chdir path
        `git checkout #{version}`
      end
      result = `git rev-parse --short HEAD`
      result.delete!("\n")
    end

    def self.update(path)
      `cd #{path} && git pull`
    end

    def self.commit(root_path, path, message)
      if self.repo_changed? path
        puts message
        Dir.chdir root_path
        path.slice! "#{root_path}/"
        `git pull`
        `git add --all #{path}`
        `git commit -m "#{message}"`
      end
    end

    def self.repo_changed?(path)
      not Exec.do "#{Application::bin}/dm_repo_clean.sh #{path}"
    end

    def self.push(root_path, version)
      Dir.chdir root_path
      `git push origin #{version}`
    end
  end

end