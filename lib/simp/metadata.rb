# vim: set expandtab ts=2 sw=2:
requires = %w[open3 tempfile tmpdir net/http uri openssl json fileutils require_all]
requires.each(&method(:require))
require_all "#{__dir__}/metadata"

module Simp
  # Main Metadata Module
  module Metadata
    attr_accessor :options, :engine, :disable_debug_output

    def self.debug_level(level)
      @debug_level = level
    end

    def self.directory_name(repo, options)
      raise "Must specify 'target'" if options[:target].nil?
      repo_name = repo.to_s.sub('_','-')
      basedir = options[:target].chomp('/')

      case repo.class.to_s
      when 'String'
        "#{basedir}/#{repo_name}"
      when 'Simp::Metadata::Repo'
        "#{basedir}/#{repo.output_filename}"
      else
        abort(Simp::Metadata.critical("Component class not recognized")[0])
      end
    end

    # ToDo: this entire logic stream is crappy.
    #      We need to replace this with a much more simplified version.
    def self.download_source(source, options)
      directory = directory_name(source, options)
      retval = {}
      case source.class.to_s
      when 'String'
        retval[:path] = directory
        # ToDo: We can bootstrap this with a hard coded source in the simp engine
        sources = {
          simp_metadata: {
            url: 'https://github.com/simp/simp-metadata',
            method: 'git'
          },
          enterprise_metadata: {
            url: 'simp-enterprise:///enterprise-metadata?version=master&filetype=tgz',
            method: 'file',
            extract: true
          }
        }
        # All this should be removed and be based on source.file_type
        source_spec = bootstrapped_sources[source]
        if source_spec[:extract]
          tarball = "#{directory}.tgz"
          fetch_from_url(source_spec, tarball, nil, options)
          Dir.mkdir(retval[:path]) unless Dir.exist?(retval[:path])
          `tar -xvpf #{tarball} -C #{retval[:path]}`
        else
          fetch_from_url(source_spec, retval[:path], nil, options)
        end
      when 'Simp::Metadata::Repo'
        retval[:path] = directory
        if options[:url]
          location = source.primary
          location.url = options[:url]
          url_spec = location
          location.method = 'git'
        else
          url_spec = source.primary
        end
        if source.method == 'file'
          FileUtils.cp_r source.url, directory
        else
          fetch_from_url(url_spec, retval[:path], source, options)
        end
      else
        raise "source.class=#{source.class}, #{source.class} is not in ['String', 'Simp::Metadata::Component']"
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

    def self.fetch_from_url(url_spec, target, repo = nil, options)
      case url_spec.class.to_s
      when 'Simp::Metadata::Location'
        url = url_spec.url
        uri = uri(url)
        method = url_spec.method
      when 'Hash'
        url = url_spec[:url]
        uri = uri(url_spec[:url])
        if url_spec.key?(:method)
          method = url_spec[:method]
        elsif url_spec.key?(:type)
          # ToDo: remove once the upstream simp-metadata has been updated so type != method
          method = if url_spec[:type] == 'git'
                     'git'
                   else
                     'file'
                   end
        else
          method = 'file'
        end
      when 'String'
        url = url_spec
        uri = uri(url_spec)
        method = 'file'
      else
        abort(critical("Invalid URL Class detected")[0])
      end

      case method
      when 'git'
        case uri.scheme
        when 'simp'
          fetch_simp_enterprise(url, target, repo, url_spec, options)
        when 'simp-enterprise'
          fetch_simp_enterprise(url, target, repo, url_spec, options)
        else
          if Dir.exist?(target)
            if options[:skip_cache_update]
              info("Skipping cache update due to `skip_cache_update` flag")
            else
              Dir.chdir(target) do
                info("Updating from #{url}")
                run('git pull origin')
              end
            end
          else
            info("Cloning from #{url}")
            run("git clone #{url} #{target}")
          end
        end
      when 'file'
        case uri.scheme
        when 'simp'
          fetch_simp_enterprise(url, target, repo, url_spec, options)
        when 'simp-enterprise'
          fetch_simp_enterprise(url, target, repo, url_spec, options)
        when 'http'
          fetch_simp_enterprise(url, target, repo, url_spec, options)
        when 'https'
          fetch_simp_enterprise(url, target, repo, url_spec, options)
        else
          raise "unsupported url type #{uri.scheme}"
        end
      else
        abort(critical("Invalid Method detected. Expected 'git' or 'file'")[0])
      end
    end

    def temp_simp_license(input = nil)
      if @temp_simp_license.nil?
        @temp_simp_license = Tempfile.new('license_data')
        @temp_simp_license.write(input) unless input.nil?
      end
      @temp_simp_license
    end

    def self.get_license_data(filename)
      ret_data = ''
      license_data = ENV.fetch('SIMP_LICENSE_KEY', nil)

      if license_data.nil?
        ret_filename = filename.class.to_s == 'String' ? filename : '/etc/simp/license.key'
        if File.exist?(ret_filename)
          ret_data = File.read(ret_filename)
        else
          temp_simp_license('')
          ret_filename = temp_simp_license.path
        end
      else
        # Environment data trumps all
        ret_data = license_data
        temp_simp_license(license_data)
        ret_filename = temp_simp_license.path
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
      port = uri.port || 443
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
        fetch_simp_enterprise(response[:location], destination, component, location)
      when '301'
        fetch_simp_enterprise(response[:location], destination, component, location)
      else
        raise "HTTP Error Code: #{response.code}"
      end
    end

    def self.run(command)
      exitcode = nil
      Open3.popen3(command) do |_stdin, stdout, stderr, thread|
        # pid = thread.pid
        Simp::Metadata.debug2(stdout.read.chomp)
        Simp::Metadata.debug1(stderr.read.chomp)
        exitcode = thread.value
      end
      exitcode
    end

    # Set Color Schemes and Message settings

    def self.level?(level)
      set_level = Simp::Metadata.convert_level(@debug_level)
      check_level = Simp::Metadata.convert_level(level)
      check_level <= set_level
    end

    def self.levels_hash
      { 'disabled' => 0, 'critical' => 1, 'error' => 2, 'warning' => 3, 'info' => 4, 'debug1' => 5, 'debug2' => 6, 'backtrace' => 7}
    end

    def self.convert_level(level)
      levels_hash[level] || 3
    end

    def self.red(text)
      "\e[41m#{text}\e[0m"
    end

    def self.yellow(text)
      "\e[30;43m#{text}\e[0m"
    end

    def self.blue(text)
      "\e[44m#{text}\e[0m"
    end

    def self.green(text)
      "\e[32m#{text}\e[0m"
    end

    def self.print_message(pre, message)
      prefix = color(pre)
      message.split("\n").each do |line|
        warn("#{prefix}: #{line}") unless @disable_debug_output
      end
    end

    def self.color(text)
      case text
      when /DEBUG/, 'INFO'
        blue(text)
      when 'WARN', 'BACKTRACE'
        yellow(text)
      when 'ERROR', 'CRITICAL'
        red(text)
      else
        text
      end
    end

    def self.debug1(message)
      Simp::Metadata.print_message('DEBUG1', message) if Simp::Metadata.level?('debug1')
    end

    def self.debug2(message)
      Simp::Metadata.print_message('DEBUG2', message) if Simp::Metadata.level?('debug2')
    end

    def self.info(message)
      Simp::Metadata.print_message('INFO', message) if Simp::Metadata.level?('info')
    end

    def self.warning(message)
      Simp::Metadata.print_message('WARN', message) if Simp::Metadata.level?('warning')
    end

    def self.error(message)
      Simp::Metadata.print_message('ERROR', message) if Simp::Metadata.level?('error')
    end

    def self.critical(message)
      Simp::Metadata.print_message('CRITICAL', message) if Simp::Metadata.level?('critical')
    end

    def self.backtrace(backtrace)
      backtrace.reverse.each { |message| Simp::Metadata.print_message('BACKTRACE', message) }
    end
  end
end
