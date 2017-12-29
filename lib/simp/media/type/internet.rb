require 'tmpdir'
require 'net/http'
require 'uri'
require 'openssl'
require 'json'
require 'open3'

module Simp
  module Media
    module Type
      class Internet < Simp::Media::Type::Base
        attr_accessor :options
        def initialize(options, engine)
          @cleanup = []
          super(options, engine)
        end

        def input_directory=(directory)
            @input_directory = directory
        end
        def input_directory
          if (@input_directory == nil)
            target = Dir.mktmpdir("cachedir")
            @cleanup << target
            @input_directory = target
          else
            @input_directory
          end
        end
        def directory_name(component, options)
          if (options["target"] != nil)
            basedir = options["target"]
          else
            basedir = self.input_directory
          end
          case component.class.to_s
            when "String"
              "#{basedir}/#{component}"
            when "Simp::Metadata::Component"
              "#{basedir}/#{component.output_filename}"
          end
        end

        def fetch_component(component, options)
          retval = {}
          case component.class.to_s
            when "String"

              retval["path"] = self.directory_name(component, options)
              # XXX: ToDo We can bootstrap this with a hard coded source in the simp engine
              bootstrapped_components = {
                  "simp-metadata" => {
                      "url" => "https://github.com/simp/simp-metadata",
                      "method" => "git"
                  },
                  "enterprise-metadata" => {
                      "url" => "simp-enterprise:///enterprise-metadata?version=master&filetype=tgz",
                      "method" => "file",
                      "extract" => true,
                  },
              }
              # All this should be removed and be based on component.file_type
              componentspec = bootstrapped_components[component]
              if (componentspec["extract"] == true)
                tarball = "#{self.directory_name(component, options)}.tgz"
                fetch_from_url(componentspec, tarball)
                unless Dir.exists?(retval["path"])
                  Dir.mkdir(retval["path"])
                end
                `tar -xvpf #{tarball} -C #{retval["path"]}`
              else
                fetch_from_url(componentspec, retval["path"])
              end
            when "Simp::Metadata::Component"
              retval["path"] = self.directory_name(component, options)
              fetch_from_url(component.primary, retval["path"], component)
          end
          return retval
        end

        def fetch_from_url(urlspec, target, component = nil)
          case urlspec.class.to_s
            when "Simp::Metadata::Location"
              url = urlspec.url
              uri = URI(url)
              method = urlspec.method
            when "Hash"
              url = urlspec["url"]
              uri = URI(urlspec["url"])
              if (urlspec.key?("method"))
                method = urlspec["method"]
              else
                # XXX ToDo remove once the upstream simp-metadata has been updated so type != method
                if (urlspec.key?("type"))
                  if (urlspec["type"] == "git")
                    method = "git"
                  else
                    method = "file"
                  end
                else
                  method = "file"
                end
              end
            when "String"
              url = urlspec
              uri = URI(urlspec)
              method = "file"
          end
          if (uri.scheme == nil)
            scheme = "file"
          else
            scheme = uri.scheme
          end
          case method
            when "git"
              unless (Dir.exists?(target))
                   info("Cloning from #{url}")
                   run("git clone #{url} #{target}")
              else
                Dir.chdir(target) do
                  info("Updating from #{url}")
                  run("git pull origin")
                end
              end
            when "file"
              case uri.scheme
                when "simp-enterprise"
                  fetch_simp_enterprise(url, target, component, urlspec)
                when "http"
                  fetch_simp_enterprise(url, target, component, urlspec)
                when "https"
                  fetch_simp_enterprise(url, target, component, urlspec)
                else
                  raise "unsupported url type #{uri.scheme}"
              end
          end
        end

        def fetch_simp_enterprise(url, destination, component, location = nil)
          if (location.class.to_s == "Simp::Metadata::Location")
            extract = location.extract
          else
            extract = false
          end
          # XXX: ToDo Move a good chunk of this into the metadata.
          uri = URI(url)
          case uri.scheme
            when "simp-enterprise"
              scheme = "https"
              host = 'enterprise-download.simp-project.com'
              filetype = 'tgz'
              version = 'latest'
              uri.query.split("&").each do |element|
                elements = element.split("=")
                if (elements.size > 1)
                  case elements[0]
                    when "version"
                      version = elements[1]
                    when "filetype"
                      filetype = elements[1]
                  end
                end
              end
              if (component != nil)
                name = "/#{component.asset_name}"
              else
                name = uri.path
              end
              path = "/products/simp-enterprise#{uri.path}#{name}-#{version}.#{filetype}"
            else
              scheme = uri.scheme
              host = uri.host
              path = uri.path
          end
          port = uri.port ? uri.port : 443
          http = Net::HTTP.new(host, port)
          case scheme
            when "https"
              http.use_ssl = true
              case uri.scheme
                when "simp-enterprise"
                  filename = self.options["license"]
                  http.ca_file = filename
                  http.cert = OpenSSL::X509::Certificate.new(File.read(filename))
                  http.key = OpenSSL::PKey::RSA.new(File.read(filename))
                  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
              end
          end
          info("Fetching from #{scheme}://#{host}:#{port}#{path}")
          req = Net::HTTP::Get.new(path)
          response = http.request(req)
          case response.code
            when '200'
              if (extract == true)
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

        def cleanup()
          @cleanup.each do |path|
            FileUtils.rmtree(path)
          end
        end
      end
    end
  end
end
