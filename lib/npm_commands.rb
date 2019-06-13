# frozen_string_literal: true

# NPM wrapper with helpful error messages
class NpmCommands
  class << self
    # @return [Boolean] whether the installation succeeded
    def install
      install_nodejs unless nodejs_installed?
    end

    def run_npm_install
      STDOUT.puts 'Installing npm dependencies...'
      Dir.chdir File.expand_path('..', __dir__) do
        `#{npm} install .`
      end
    end

    def npm
      @@npm
    end

    def node
      @@node
    end

    private

    def nodejs_installed?
      return true if executable?('node') && executable?('npm')
    end

    def executable?(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end

    def install_nodejs
      unless host_os.include?('linux') && architecture.include?('x86_64')
        throw 'Install nodejs failed. Only support linux amd64.'
      end
      Dir.chdir File.expand_path('..', __dir__) do
        `wget https://nodejs.org/dist/v6.11.2/#{node_filename}.tar.gz`
        `tar xzf #{node_filename}.tar.gz`
      end
    end

    def host_os
      RbConfig::CONFIG['host_os']
    end

    def architecture
      RbConfig::CONFIG['host_cpu']
    end

    def node_filename
      'node-v6.11.2-linux-x64'
    end

    def node_path(command)
      File.expand_path("../#{node_filename}/bin/#{command}", __dir__)
    end
  end

  @@node, @@npm = nodejs_installed? ? ['node', 'npm'] : [node_path('node'), node_path('npm')]
end