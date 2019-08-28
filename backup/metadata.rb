# vim: set expandtab ts=2 sw=2:
requires = [ 'open3', 'tempfile', 'tmpdir', 'net/http', 'uri', 'openssl', 'json', 'fileutils', 'require_all' ]
requires.each(&method(:require))
require_all 'lib/simp/metadata'

module Simp
  module Metadata

    def directory_name(component, options)
      if options[:target].nil?
        raise "Must specify 'target'"
      else
        basedir = options[:target]
      end

      case component.class.to_s
      when 'String'
        "#{basedir}/#{component}"
      when 'Simp::Metadata::Component'
        "#{basedir}/#{component.output_filename}"
      end
    end

    # ToDo: this entire logic stream is crappy.
    #      We need to replace this with a much more simplified version.
    def self.download_component(component, options)
      directory = directory_name(component, options)
      retval = {}
      case component.class.to_s
      when 'String'
        retval[:path] = directory_name(component, options)
        # ToDo: We can bootstrap this with a hard coded source in the simp engine
        bootstrapped_components = {
          'simp-metadata' => {
            'url' => 'https://github.com/simp/simp-metadata',
            'method' => 'git'
          },
          'enterprise-metadata' => {
            'url' => 'simp-enterprise:///enterprise-metadata?version=master&filetype=tgz',
            'method' => 'file',
            'extract' => true
          }
        }
        # All this should be removed and be based on component.file_type
        component_spec = bootstrapped_components[component]
        if component_spec[:extract]
          tarball = "#{directory}.tgz"
          fetch_from_url(component_spec, tarball, nil, options)
          Dir.mkdir(retval['path']) unless Dir.exist?(retval['path'])
          `tar -xvpf #{tarball} -C #{retval[:path]}`
        else
          fetch_from_url(component_spec, retval['path'], nil, options)
        end
      when 'Simp::Metadata::Component'
        retval['path'] = directory
        if options[:url]
          location = component.primary
          location.url = options[:url]
          url_spec = location
          location.method = 'git'
        else
          url_spec = component.primary
        end
        if component.method == 'file'
          FileUtils.cp_r component.url, directory
        else
          fetch_from_url(url_spec, retval['path'], component, options)
        end
      else
        raise "component.class=#{component.class}, #{component.class} is not in ['String', 'Simp::Metadata::Component']"
      end
      retval
    end

    def self.uri(url)
      case url
      when /git@/
        uri = Simp::Metadata::FakeURI.new(uri)
        uri.scheme = 'ssh'
        uri
      else
        URI(url)
      end
    end

    def self.fetch_from_url(url_spec, target, component = nil, options)
      case url_spec.class.to_s
      when 'Simp::Metadata::Location'
        url = url_spec.url
        uri = uri(url)
        method = url_spec.method
      when 'Hash'
        url = url_spec['url']
        uri = uri(url_spec['url'])
        if url_spec.key?('method')
          method = url_spec['method']
        else
          # ToDo: remove once the upstream simp-metadata has been updated so type != method
          if url_spec.key?('type')
            method = if url_spec['type'] == 'git'
                       'git'
                     else
                       'file'
                     end
          else
            method = 'file'
          end
        end
      when 'String'
        url = url_spec
        uri = uri(url_spec)
        method = 'file'
      else
        abort(self.critical("Invalid URL Class detected")[0])
      end

      def cache_dir(version, upstream)
        if ENV['XDG_CACHE_HOME']
          "#{ENV['XDG_CACHE_HOME']}/simp-metadata/#{version}/#{upstream}"
        else
          "#{ENV['HOME']}/.cache/simp-metadata/#{version}/#{upstream}"
        end
        # cache = cache_dir('simp', url.split('/')[-2].to_s)
      end

      case method
      when 'git'
        case uri.scheme
        when 'simp'
          fetch_simp_enterprise(url, target, component, url_spec, options)
        when 'simp-enterprise'
          fetch_simp_enterprise(url, target, component, url_spec, options)
        else
          if Dir.exist?(target)
            Dir.chdir(target) do
              info("Updating from #{url}")
              run('git pull origin')
            end
          else
    #        if Dir.exist?(cache_dir)
    #          Dir.chdir(cache_dir) do
    #            info("Updating from #{url}")
    #            run('git pull origin')
    #          end
    #        else
              info("Cloning from #{url}")
     #         info("Creating cache at #{cache_dir}")
              require 'pry'; require 'pry-byebug'; binding.pry
              run("git clone #{url} #{target}")
     #       end
          end
        end
      when 'file'
        case uri.scheme
        when 'simp'
          fetch_simp_enterprise(url, target, component, url_spec, options)
        when 'simp-enterprise'
          fetch_simp_enterprise(url, target, component, url_spec, options)
        when 'http'
          fetch_simp_enterprise(url, target, component, url_spec, options)
        when 'https'
          fetch_simp_enterprise(url, target, component, url_spec, options)
        else
          raise "unsupported url type #{uri.scheme}"
        end
      else
        abort(self.critical("Invalid Method detected. Expected 'git' or 'file'")[0])
      end
    end

    def self.get_license_data(filename)
      ret_data = ''
      license_data = ENV.fetch('SIMP_LICENSE_KEY', nil)
      if !license_data.nil?
        # Environment data trumps all
        ret_data = license_data
        if $simp_license_temp.nil?
          $simp_license_temp = Tempfile.new('license_data')
          $simp_license_temp.write(license_data)
        end
        ret_filename = $simp_license_temp.path
      else
        ret_filename = if filename.class.to_s == 'String'
                         # Attempt to load from the filename passed
                         filename
                       else
                         # Try to load from /etc/simp/license.key file
                         '/etc/simp/license.key'
                       end
        if File.exist?(ret_filename)
          ret_data = File.read(ret_filename)
        else
          if $simp_license_temp.nil?
            $simp_license_temp = Tempfile.new('license_data')
            $simp_license_temp.write('')
          end
          ret_filename = $simp_license_temp.path
        end
      end
      [ret_filename, ret_data]
    end

    def self.fetch_simp_enterprise(url, destination, component, location = nil, options)
      extract = if location.class.to_s == 'Simp::Metadata::Location'
                  location.extract
                else
                  false
                end
      uri = uri(url)

      case uri.scheme
      when 'simp-enterprise'
        scheme = 'https'
        host = 'enterprise-download.simp-project.com'
        filetype = 'tgz'
        unless component.nil?
          filetype = component.extension if component.extension != ''
        end
        version = 'latest'
        unless component.nil?
          version = component.version if component.version != ''
        end
        unless uri.query.nil?
          uri.query.split('&').each do |element|
            next unless element.class.to_s == 'String'
            elements = element.split('=')
            next unless elements.size > 1
            case elements[0]
            when 'version'
              version = elements[1]
            when 'filetype'
              filetype = elements[1]
            end
          end
        end

        name = if !component.nil?
                 "/#{component.name}/#{component.binaryname}"
               else
                 "#{uri.path}#{uri.path}#{name}-#{version}.#{filetype}"
               end
        path = "/products/simp-enterprise#{name}"
      when 'simp'
        scheme = 'https'
        host = 'download.simp-project.com'
        filetype = 'tgz'
        unless component.nil?
          filetype = component.extension if component.extension != ''
        end
        version = 'latest'
        unless component.nil?
          version = component.version if component.version != ''
        end
        unless uri.query.nil?
          uri.query.split('&').each do |element|
            next unless element.class.to_s == 'String'
            elements = element.split('=')
            next unless elements.size > 1
            case elements[0]
            when 'version'
              version = elements[1]
            when 'filetype'
              filetype = elements[1]
            end
          end
        end
        name = if !component.nil?
                 "/#{component.name}/#{component.binaryname}"
               else
                 "#{uri.path}#{uri.path}#{name}-#{version}.#{filetype}"
               end
        path = "/SIMP/assets#{name}"
      else
        scheme = uri.scheme
        host = uri.host
        path = uri.path
      end
      port = uri.port ? uri.port : 443
      http = Net::HTTP.new(host, port)

      case scheme
      when 'https'
        http.use_ssl = true
        case uri.scheme
        when 'simp-enterprise'
          filename, data = get_license_data(options[:license])
          http.ca_file = filename unless filename.nil?
          unless data.nil?
            http.cert = OpenSSL::X509::Certificate.new(data)
            http.key = OpenSSL::PKey::RSA.new(data)
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          end

          debug2("using the following certificate (#{filename}) for client certificate auth: #{http.cert.subject}")
        end
      end
      info("Fetching from #{scheme}://#{host}:#{port}#{path}")
      req = Net::HTTP::Get.new(path)
      response = http.request(req)
      case response.code
      when '200'
        if extract
          File.open("#{destination}.tgz", 'w') do |f|
            f.write response.body
          end
          FileUtils.mkdir_p(destination)
          run("tar -xvpf #{destination}.tgz -C #{destination}")
        else
          File.open(destination, 'w') do |f|
            f.write response.body
          end
        end
      when '302'
        fetch_simp_enterprise(response['location'], destination, component, location)
      when '301'
        fetch_simp_enterprise(response['location'], destination, component, location)
      else
        $errorcode = response.code.to_i
        raise "HTTP Error Code: #{response.code}"
      end
    end

    def self.run(command)
      exitcode = nil
      Open3.popen3(command) do |_stdin, stdout, stderr, thread|
        pid = thread.pid
        Simp::Metadata.debug2(stdout.read.chomp)
        Simp::Metadata.debug1(stderr.read.chomp)
        exitcode = thread.value
      end
      exitcode
    end

    def self.level?(level)
      setlevel = Simp::Metadata.convert_level($simp_metadata_debug_level)
      checklevel = Simp::Metadata.convert_level(level)
      if checklevel <= setlevel
        true
      else
        false
      end
    end

    def self.convert_level(level)
      case level
      when 'disabled'
        0
      when 'critical'
        1
      when 'error'
        2
      when 'warning'
        3
      when 'info'
        4
      when 'debug1'
        5
      when 'debug2'
        6
      else
        3
      end
    end

    def self.print_message(prefix, message)
      message.split("\n").each do |line|
        output = "#{prefix}: #{line}"
        STDERR.puts output unless $simp_metadata_debug_output_disabled
      end
    end

    def self.debug1(message)
      if Simp::Metadata.level?('debug1')
        Simp::Metadata.print_message('DEBUG1', message)
      end
    end

    def self.debug2(message)
      if Simp::Metadata.level?('debug2')
        Simp::Metadata.print_message('DEBUG2', message)
      end
    end

    def self.info(message)
      if Simp::Metadata.level?('info')
        Simp::Metadata.print_message('INFO', message)
      end
    end

    def self.warning(message)
      if Simp::Metadata.level?('warning')
        Simp::Metadata.print_message('WARN', message)
      end
    end

    def self.error(message)
      if Simp::Metadata.level?('error')
        Simp::Metadata.print_message('ERROR', message)
      end
    end

    def self.critical(message)
      if Simp::Metadata.level?('critical')
        Simp::Metadata.print_message('CRITICAL', message)
      end
    end
  end
end
