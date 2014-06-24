require 'fileutils'
require 'docman/info'

module Docman

  class DocrootConfig

    attr_reader :structure, :deploy_target, :docroot_dir, :root
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
      info['name'] = name
      info['parent'] = parent
      info['children'] = children

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

    def states_dependin_on(name, version)
      states = {}
      @names[name]['states'].each do |state, info|
        states[state] = info if info['version'] == version
      end
      states
    end

  end
end