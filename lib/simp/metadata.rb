# vim: set expandtab ts=2 sw=2:
requires = %w[open3 tempfile tmpdir net/http uri openssl json fileutils require_all]
requires.each(&method(:require))
require_all "#{__dir__}/metadata"

module Simp
  # Main Metadata Module
  module Metadata
    class << self
      attr_accessor :options, :engine

      def directory_name(repo, options)
        raise "Must specify 'target'" if options[:target].nil?

        repo_name = repo.to_s.sub('_', '-')
        basedir = options[:target].chomp('/')

        case repo.class.to_s
        #when 'String'
        #  "#{basedir}/#{repo_name}"
        when 'Simp::Metadata::Repo'
          "#{basedir}/#{repo.output_filename}"
        else
          abort(Simp::Metadata::Debug.critical("Source class not recognized")[0])
        end
      end

      # TODO: this entire logic stream is crappy.
      #      We need to replace this with a much more simplified version.
      def download_source(source, options)
        directory = directory_name(source, options)
        retval = {}
        case source.class.to_s
        #when 'String'
        #  retval[:path] = directory
        #  # TODO: We can bootstrap this with a hard coded source in the simp engine
        #  sources = { simp_metadata: { url: 'https://github.com/simp/simp-metadata', method: 'git' },
        #              enterprise_metadata: { url: 'simp-enterprise:///enterprise-metadata?version=master&filetype=tgz',
        #                                     method: 'file',
        #                                     extract: true } }
        #  # All this should be removed and be based on source.file_type
        #  source_spec = sources[source]
        #  if source_spec[:extract]
        #    tarball = "#{directory}.tgz"
        #    fetch_from_url(source_spec, tarball, options)
        #    Dir.mkdir(retval[:path]) unless Dir.exist?(retval[:path])
        #    `tar -xvpf #{tarball} -C #{retval[:path]}`
        #  else
        #    fetch_from_url(source_spec, retval[:path], options)
        #  end
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
          # if source.method == 'file'
          #  FileUtils.cp_r source.url, directory
          # else
          fetch_from_url(url_spec, retval[:path], options, source)
          # end
        else
          raise "source.class=#{source.class}, #{source.class} is not in ['String', 'Simp::Metadata::Repo']"
        end
        retval
      end

      def uri(url)
        case url
        when /git@/
          uri = Simp::Metadata::FakeURI.new(uri)
          uri.scheme = 'ssh'
          uri
        else
          URI(url)
        end
      end

      def fetch_from_url(url_spec, target, options, repo = nil)
        url, method = grab_url_info(url_spec)
        uri = uri(url)
        case method
        when 'git'
          case uri.scheme
          when 'simp', 'simp-enterprise'
            fetch_simp_enterprise(url, target, repo, options, url_spec)
          else
            git_staging(target, url, options)
          end
        when 'file'
          case uri.scheme
          when 'simp', 'simp-enterprise', 'http', 'https'
            fetch_simp_enterprise(url, target, repo, options, url_spec)
          else
            raise "unsupported url type #{uri.scheme}"
          end
        else
          abort(critical("Invalid Method detected. Expected 'git' or 'file'")[0])
        end
      end

      def grab_url_info(url_spec)
        case url_spec.class.to_s
        when 'Simp::Metadata::Location'
          url = url_spec.url
          method = url_spec.method
        when 'Hash'
          url = url_spec[:url]
          # TODO: remove once the upstream simp-metadata has been updated so type != method
          method = if url_spec.key?(:method)
                     url_spec[:method]
                   elsif url_spec[:type] == 'git'
                     'git'
                   else
                     'file'
                   end
        when 'String'
          url = url_spec
          method = 'file'
        else
          Simp::Metadata::Debug.abort(critical("Invalid URL Class detected")[0])
        end
        [url, method]
      end

      def git_staging(target, url, options)
        if Dir.exist?(target)
          if options[:skip_cache_update]
            Simp::Metadata::Debug.info("Skipping cache update due to `skip_cache_update` flag")
          else
            Dir.chdir(target) do
              Simp::Metadata::Debug.info("Updating from #{url}")
              run('git pull origin')
            end
          end
        else
          Simp::Metadata::Debug.info("Cloning from #{url}")
          run("git clone #{url} #{target}")
        end
      end

      def temp_simp_license(input = nil)
        if @temp_simp_license.nil?
          @temp_simp_license = Tempfile.new('license_data')
          @temp_simp_license.write(input) unless input.nil?
        end
        @temp_simp_license
      end

      def get_license_data(filename)
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

      def fetch_simp_enterprise(url, destination, repo, options, location = nil)
        base_dir = options[:target].chomp('/')
        FileUtils.makedirs(base_dir)
        extract = case location.class.to_s
                  when 'Simp::Metadata::Location'
                    location.extract
                  when 'Hash'
                    location[:extract]
                  end
        uri = uri(url)

        scheme, host, path = grab_host_data(uri, base_dir, repo)

        port = uri.port || 443
        http = http_ssl_set(uri, options, scheme, host, port)

        Simp::Metadata::Debug.info("Fetching from #{scheme}://#{host}:#{port}#{path}")
        req = Net::HTTP::Get.new(path)
        response = http.request(req)
        response_case(response, extract, destination)
      end

      def http_ssl_set(uri, options, scheme, host, port)
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
            debug_msg = "Using the following certificate (#{filename}) for client certificate auth: #{http.cert.subject}"
            Simp::Metadata::Debug.debug2(debug_msg)
          end
        end
        http
      end

      def response_case(response, extract, destination)
        case response.code
        when '200'
          File.open("#{destination}.tgz", 'w') { |f| f.write response.body }
          if extract
            FileUtils.mkdir_p(destination)
            run("tar -xvpf #{destination}.tgz -C #{destination}")
          end
        when '302', '301'
          fetch_simp_enterprise(response[:location], destination, repo, {}, location)
        else
          raise "HTTP Error Code: #{response.code}"
        end
      end

      def main_project_dir
        base = __dir__
        base.split('/')[0..-3].join('/')
      end

      def grab_host_data(uri, base_dir, repo)
        case uri.scheme
        when 'simp-enterprise', 'simp'
          host = 'download.simp-project.com'
          host.prepend('enterprise-') if uri.scheme == 'simp-enterprise'
          scheme = 'https'
          version, filetype = host_metadata(uri, repo)
          path = set_repo_path(uri, repo, version, filetype)
          FileUtils.makedirs("#{base_dir}/#{uri.scheme}")
        else
          scheme = uri.scheme
          host = uri.host
          path = uri.path
        end
        [scheme, host, path]
      end

      def host_metadata(uri, repo)
        base_filetype = repo.extension.empty? ? 'tgz' : repo.extension
        base_version = repo.version.empty? ? 'latest' : repo.version
        unless repo.nil?
          base_filetype = repo.extension unless repo.extension == ''
          base_version = repo.version unless repo.version == ''
        end
        uri_hash = {}
        unless uri.query.nil?
          uri.query.split('&').each { |keys| keys.scan(/(\w+)=(\w+)/).map { |k, v| uri_hash[k.to_sym] = v.to_s } }
        end
        version = uri_hash[:version] || base_version
        filetype = uri_hash[:filetype] || base_filetype
        [version, filetype]
      end

      def set_repo_path(uri, repo, version, filetype)
        scheme = uri.scheme
        name = repo_name(uri, repo, version, filetype)
        if scheme == 'simp-enterprise'
          "/products/simp-enterprise/#{name}"
        elsif scheme == 'simp'
          "/SIMP/assets/#{name}"
        end
      end

      def repo_name(uri, repo, version, filetype)
        scheme = uri.scheme
        uri_path = uri.path.slice(1..-1)
        repo_name = if scheme == 'simp-enterprise'
                      repo.path_name
                    else
                      repo.name
                    end
        if repo.nil?
          "#{uri_path}/#{uri_path}/#{repo_name}-#{version}.#{filetype}"
        else
          "#{repo_name}/#{repo.binaryname}"
        end
      end

      def run(command)
        exitcode = nil
        Open3.popen3(command) do |_stdin, stdout, stderr, thread|
          pid = thread.pid.to_s
          Simp::Metadata::Debug.debug2(stdout.read.chomp)
          Simp::Metadata::Debug.info("PID: #{pid}")
          Simp::Metadata::Debug.debug1(stderr.read.chomp)
          exitcode = thread.value
        end
        exitcode
      end
    end
  end
end
