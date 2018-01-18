require 'application'
require 'fileutils'
require 'docman/info'

module Docman

  class DocrootConfig

    attr_reader :structure, :deploy_target, :docroot_dir, :docroot_config_dir, :config_dir, :root, :raw_infos

    def initialize(docroot_dir, deploy_target_name = nil, options = nil)
      @override = {}
      if options && options['config']
        @override = JSON.parse(options['config'])
      end
      @docroot_dir = docroot_dir
      #@deploy_target = deploy_target
      @docroot_config_dir = File.join(docroot_dir, 'config')

      Dir.chdir @docroot_config_dir
      unless options.key? :config_dir
        update('origin')
      end
      config_files = Docman::Application.instance.config_dirs(options).collect{|item|
        File.join(@docroot_config_dir, item, 'config.{yaml,yml}')
      }
      config_file_path = Dir.glob(config_files).first

      raise "Configuration file config.{yaml,yml} not found." if config_file_path.nil?

      @config_dir = File.dirname(config_file_path)
      @config_file = File.basename(config_file_path)

      Docman::Application.instance.config.merge_config_from_file(docroot_dir, @config_dir, @config_file, options)

      if deploy_target_name
        @deploy_target = Application.instance.config['deploy_targets'][deploy_target_name]
        raise "Wrong deploy target: #{deploy_target_name}" if @deploy_target.nil?
        @deploy_target['name'] = deploy_target_name
      end

      @names = {}
      @raw_infos = {}
      master_file = File.join(@docroot_config_dir, 'master')
      if File.directory? master_file
        @structure = structure_build(File.join(@docroot_config_dir, 'master'))
      else
        @structure = structure_build_from_config_file(Docman::Application.instance.config)
      end
    end

    def update(options = '')
      Dir.chdir @docroot_config_dir
      GitUtil.exec("reset --hard", false)
      branch = GitUtil.branch
      GitUtil.update @docroot_config_dir, "#{options} #{branch.strip}"
    end

    def structure_build_from_config_file(config, prefix = '', parent = nil, parent_key = 'master')
      return if config['components'][parent_key].nil?
      children = []

      info = config['components'][parent_key]

      children_components_config = nil
      unless info['components'].nil?
        children_components_config = {'components' => info.delete('components')}
      end

      @raw_infos[parent_key] = info

      unless info['status'].nil?
        return if info['status'] == 'disabled'
      end

      name = parent_key
      prefix = prefix.size > 0 ? File.join(prefix, name) : name
      info['full_path'] = @docroot_config_dir
      info['docroot_config'] = self
      info['build_path'] = prefix
      info['full_build_path'] = File.join(@docroot_dir, prefix)
      info['temp_path'] = File.join(@docroot_dir, '.docman/tmp', info['build_path'])
      info['states_path'] = File.join(@docroot_dir, '.docman/states', info['build_path'])
      info['name'] = name
      info['parent'] = parent
      info['order'] = info.has_key?('order') ? info['order'] : 10
      info['children'] = children

      if @override['projects'] && @override['projects'].key?(info['name'])
        info.merge! @override['projects'][info['name']]
      end

      i = Docman::Info.new(info)
      @root = i if parent.nil?
      i['root'] = @root

      @names[name.to_s] = i

      unless children_components_config.nil?
        children_components_config['components'].each {|child_name, child_config|
          children << structure_build_from_config_file(children_components_config, prefix, i, child_name)
        }
      end
      i
    end

    def structure_build(path, prefix = '', parent = nil)
      return unless File.file? File.join(path, 'info.yaml')

      children = []
      info = YAML::load_file(File.join(path, 'info.yaml'))
      @raw_infos[File.basename path] = YAML::load_file(File.join(path, 'info.yaml'))
      unless info['status'].nil?
        return if info['status'] == 'disabled'
      end
      name = File.basename path
      prefix = prefix.size > 0 ? File.join(prefix, name) : name
      info['full_path'] = path
      info['docroot_config'] = self
      info['build_path'] = prefix
      info['full_build_path'] = File.join(@docroot_dir, prefix)
      info['temp_path'] = File.join(@docroot_dir, '.docman/tmp', info['build_path'])
      info['states_path'] = File.join(@docroot_dir, '.docman/states', info['build_path'])
      info['name'] = name
      info['parent'] = parent
      info['order'] = info.has_key?('order') ? info['order'] : 10
      info['children'] = children

      if @override['projects'] && @override['projects'].key?(info['name'])
        info.merge! @override['projects'][info['name']]
      end

      i = Docman::Info.new(info)
      @root = i if parent.nil?
      i['root'] = @root

      @names[name.to_s] = i

      Dir.foreach(path) do |entry|
        next if (entry == '..' || entry == '.')
        full_path = File.join(path, entry)
        if File.directory?(full_path)
          dir_hash = structure_build(full_path, prefix, i)
          unless dir_hash == nil
            children << dir_hash
          end
        end
      end
      i
    end

    def chain(info)
      chain = {}
      chain[info['name']] = info
      while info['parent'] do
        chain[info['parent']['name']] = info['parent']
        info = info['parent']
      end
      Hash[chain.to_a.reverse!]
    end

    def info_by(name)
      @names[name]
    end

    def project(name)
      raise "There is no project with name '#{name}' exists in config" unless @names.has_key? name
      @names[name]
    end

    def states_dependin_on(name, version)
      states = {}
      master_project = project(name)
      if master_project.has_key?('states_project')
        states_project = project(master_project['states_project'])
        states_project.states.each do |state, info|
          states[state] = info if info['version'] == version
        end
      else
        master_project.states.each do |state, info|
          states[state] = info if info['version'] == version
        end
      end
      states
    end

    def config_hash
      Digest::MD5.hexdigest(Marshal::dump(@raw_infos))
    end

    def deploy_target_name
      @deploy_target.name
    end

  end
end
