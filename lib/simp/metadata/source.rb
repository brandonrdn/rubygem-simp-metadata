require 'yaml'
require 'uri'

module Simp
  module Metadata
    class Source

      attr_accessor :url
      attr_accessor :cachepath
      attr_accessor :components
      attr_accessor :releases
      attr_accessor :basename
      attr_accessor :data
      attr_accessor :releases
      attr_accessor :components
      attr_accessor :name
      attr_accessor :write_url
      attr_accessor :edition

      def initialize(args = {})
        @name = args[:name]
        @edition = args[:edition]
        url = args[:url]
        @write_url = url
        @url = url
        cachepath = args[:cachepath]
        uri = URI(url)
        @components = {}
        @releases = {}
        @data = {}
        @releases = {}
        @components = {}
        @cleanup = []
        if (uri.scheme == "file" or uri.scheme == nil)
          load_from_dir(uri.path)
        else
          if (cachepath == nil)
            @cachepath = Dir.mktmpdir("cachedir")
            @cleanup << @cachepath
          else
            @cachepath = File.absolute_path(cachepath);
          end
          @basename = File.basename(url, File.extname(url))
          Dir.chdir(@cachepath) do
            unless (Dir.exists?(@cachepath + "/" + basename))
              Simp::Metadata.run("git clone #{url} #{basename}")
            else
              Dir.chdir(@cachepath + "/" + @basename) do
                begin
                  Simp::Metadata.run("git pull origin")
                end
              end
            end
            load_from_dir(@cachepath + "/" + @basename)
          end
        end
        unless @data['releases'] == nil
          @releases = @data['releases']
        end
        unless @data['components'] == nil
          @components = @data['components']
        end
        @dirty = false
      end
      def to_s()
        self.name
      end
      def release(version)
        if (self.releases.key?(version))
          self.releases[version]
        else
          {}
        end
      end
      def delete_release(version)
        if (@releases.key?(version))
          self.dirty = true
          @releases.delete(version)
        end
      end
      def create_release(destination, source = 'master')
        if (@releases.key?(destination))
          raise "destination version #{destination} already exists"
        end
        unless (@releases.key?(source))
          raise "source version #{source} doesn't exist"
        end
        self.dirty = true
        @releases[destination] = Marshal.load(Marshal.dump(@releases[source]))
      end

      def dirty?()
        @dirty
      end

      def dirty=(value)
        @dirty = value
      end
      def save()
        if (self.dirty? == true)
          puts @load_path
          # XXX ToDo: Write files to yaml, commit and push (where appropriate)

          Simp::Metadata.run("cd #{@load_path} && rm -rf v1")
          FileUtils.mkdir_p("#{@load_path}/v1/releases")
          File.open("#{@load_path}/v1/components.yaml", 'w') { |file| file.write({ "components" => @components}.to_yaml) }
          @releases.each do |releasename, data|
            File.open("#{@load_path}/v1/releases/#{releasename}.yaml", 'w') { |file| file.write({ "releases" => { "#{releasename}" => data}}.to_yaml) }
          end
          Simp::Metadata.run("cd #{@load_path} && git remote add upstream #{write_url}")
          Simp::Metadata.run("cd #{@load_path} && git remote set-url upstream #{write_url}")
          Simp::Metadata.run("cd #{@load_path} && git add -A && git commit -m 'Automatically updated via simp-metadata save'; git push upstream master")
          self.dirty = false
        end
      end

      def load_from_dir(path)
        @load_path = path
        Dir.chdir(path) do
          Dir.glob("**/*.yaml") do |filename|
            begin
              hash = YAML.load_file(filename)
              @data = deep_merge(@data, hash)
            end
          end
        end
      end

      def deep_merge(target_hash, source_hash)
        source_hash.each do |key, value|
          if (target_hash.key?(key))
            if (value.class == Hash)
              self.deep_merge(target_hash[key], value)
            else
              target_hash[key] = value
            end
          else
            target_hash[key] = value
          end
        end
        target_hash
      end
      def cleanup()
        @cleanup.each do |path|
          FileUtils.rmtree(path)
        end
      end
    end
  end
end

