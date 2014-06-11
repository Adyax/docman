require 'fileutils'
require 'docman/info'

module Docman

  class DocrootConfig

    attr_reader :structure, :deploy_target, :docroot_dir
    def initialize(docroot_dir, deploy_target)
      @docroot_dir = docroot_dir
      @deploy_target = deploy_target
      @docroot_config_dir = File.join(docroot_dir, 'config')
      update
      @names = {}
      @structure = structure_build File.join(@docroot_config_dir, 'master')
    end

    def update
      GitUtil.update @docroot_config_dir
    end

    def structure_build(path, prefix = '', parent = nil)
      return unless File.file? File.join(path, 'info.yaml')

      children = []
      info = YAML::load_file(File.join(path, 'info.yaml'))
      name = File.basename path
      prefix = prefix.size > 0 ? File.join(prefix, name) : name
      info['full_path'] = path
      info['docroot_config'] = self
      info['build_path'] = prefix
      info['full_build_path'] = File.join(@docroot_dir, prefix)
      info['temp_path'] = File.join(@docroot_dir, 'tmp', info['build_path'])
      info['name'] = name
      info['parent'] = parent
      info['children'] = children

      i = Docman::Info.new(info)

      @names[name.to_s] = i

      data = [i]
      # data[:children] = children
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

    def root(info)
      chain(info).each do |name, item|
        if item['type'] == 'root'
          return item
        end
      end
    end

    def root_dir
      @structure[:data]
    end

    def info_by(name)
      @names[name]
    end

    def states_dependin_on(name, version)
      states = {}
      @names[name]['states'].each do |state, info|
        states[state] = info if info['version'] == version
      end
      states
    end

  end
end