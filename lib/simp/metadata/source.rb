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

      def initialize(url, cachepath = nil)
        @url = url
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

      def release(version)
        if (self.releases.key?(version))
          self.releases[version]
        else
          {}
        end
      end
      def dirty?()
        @dirty
      end
      def save()
        if (self.dirty? == true)
          # XXX ToDo: Write files to yaml, commit and push (where appropriate)
        end
      end

      def load_from_dir(path)
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

