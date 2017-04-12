require 'fileutils'
require 'docman/info'

module Docman

  class DocrootConfig

    attr_reader :structure, :deploy_target, :docroot_dir, :root, :raw_infos

    def initialize(docroot_dir, deploy_target = nil, options = nil)
      @override = {}
      if options && options['config']
        @override = JSON.parse(options['config'])
      end
      @docroot_dir = docroot_dir
      @deploy_target = deploy_target
      @docroot_config_dir = File.join(docroot_dir, 'config')
      update(' origin master')
      if File.file? File.join(@docroot_config_dir, 'config.yaml')
        Docman::Application.instance.config.merge_config_from_file(@docroot_config_dir, 'config.yaml', options)
      end
      @names = {}
      @raw_infos = {}
      master_file = File.join(@docroot_config_dir, 'master')
      if File.directory? master_file
        @structure = structure_build(File.join(@docroot_config_dir, 'master'))
      else
        @structure = structure_build_from_config_file(File.join(@docroot_config_dir, 'master'))
      end
    end

    def update(options = '')
      GitUtil.update @docroot_config_dir, options
    end

    def structure_build_from_config_file(path, prefix = '', parent = nil, parent_key = 'master')
      config = Docman::Application.instance.config
      return if config['components'][parent_key].nil?
      children = []

      info = config['components'][parent_key]
      @raw_infos[parent_key] = info

      unless info['status'].nil?
        return if info['status'] == 'disabled'
      end

      name = parent_key
      prefix = prefix.size > 0 ? File.join(prefix, name) : name
      info['full_path'] = path
      info['docroot_config'] = self
      info['build_path'] = prefix
      info['full_build_path'] = File.join(@docroot_dir, prefix)
      info['temp_path'] = File.join(@docroot_dir, 'tmp', info['build_path'])
      info['states_path'] = File.join(@docroot_dir, 'states', info['build_path'])
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

      # Dir.foreach(path) do |entry|
      #   next if (entry == '..' || entry == '.')
      #   full_path = File.join(path, entry)
      #   if File.directory?(full_path)
      #     dir_hash = structure_build(full_path, prefix, i)
      #     unless dir_hash == nil
      #       children << dir_hash
      #     end
      #   end
      # end
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
      info['temp_path'] = File.join(@docroot_dir, 'tmp', info['build_path'])
      info['states_path'] = File.join(@docroot_dir, 'states', info['build_path'])
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
      project(name).states.each do |state, info|
        states[state] = info if info['version'] == version
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