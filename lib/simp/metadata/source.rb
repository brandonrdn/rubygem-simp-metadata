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
      attr_accessor :edition
      attr_accessor :engine

      def initialize(args)
        unless args.key?(:engine)
          raise ':engine must be specified when initializing a metadata source'
        end
        unless args.key?(:name)
          raise ':name must be specified when initializing a metadata source'
        end
        unless args.key?(:component)
          raise ':component must be specified when initializing a metadata source'
        end
        unless args.key?(:edition)
          raise ':edition must be specified when initializing a metadata source'
        end

        @engine = args[:engine]
        @name = args[:name]
        @component = args[:component]
        @edition = args[:edition]

        @url = if args[:url]
                 args[:url]
               else
                 @component.primary.url
               end
        @write_url = @url
        cachepath = args[:cachepath]
        @components = {}
        @releases = {}
        @data = {}
        @cleanup = []

        if cachepath.nil?
          @cachepath = Dir.mktmpdir('cachedir')
          @cleanup << @cachepath
        else
          @cachepath = File.absolute_path(cachepath)
        end
        retval = Simp::Metadata.download_component(@component, 'target' => @cachepath)
        load_from_dir(retval['path'])

        @dirty = false
      end

      def to_s
        name
      end

      def writable?
        true
      end

      attr_reader :write_url

      def write_url=(value)
        if value != @url
          @write_url = value
          FileUtils.rm_r("#{@cachepath}/#{@component.name}")
          retval = Simp::Metadata.download_component(@component, 'target' => @cachepath, 'url' => value)
          load_from_dir(retval['path'])
        end
      end

      def release(version)
        if releases.key?(version)
          releases[version]
        else
          {}
        end
      end

      def delete_release(version)
        if @releases.key?(version)
          self.dirty = true
          @releases.delete(version)
        end
      end

      def create_release(destination, source = 'master')
        if @releases.key?(destination)
          raise "destination version #{destination} already exists"
        end
        unless @releases.key?(source)
          raise "source version #{source} doesn't exist"
        end
        self.dirty = true
        @releases[destination] = Marshal.load(Marshal.dump(@releases[source]))
      end

      def dirty?
        @dirty
      end

      attr_writer :dirty

      def save(message = 'Auto-saving using simp-metadata')
        if dirty?
          puts @load_path
          # XXX ToDo: Write files to yaml, commit and push (where appropriate)

          Simp::Metadata.run("cd #{@load_path} && rm -rf v1")
          FileUtils.mkdir_p("#{@load_path}/v1")
          File.open("#{@load_path}/v1/components.yaml", 'w') { |file| file.write({ 'components' => @components }.to_yaml) }
          @releases.each do |releasename, data|
            directory = case releasename
                        when /.*-[Aa][Ll][Pp][Hh][Aa].*/
                          'prereleases'
                        when /.*-[Bb][Ee][Tt][Aa].*/
                          'prereleases'
                        when /.*-[Rr][Cc].*/
                          'prereleases'
                        when /^nightly-/
                          'nightlies'
                        when /develop/
                          'channels'
                        when /development/
                          'channels'
                        when /master/
                          'channels'
                        when /^test-/
                          'tests'
                        else
                          'releases'
                        end
            FileUtils.mkdir_p("#{@load_path}/v1/#{directory}")
            File.open("#{@load_path}/v1/#{directory}/#{releasename}.yaml", 'w') { |file| file.write({ 'releases' => { releasename.to_s => data } }.to_yaml) }
          end
          Simp::Metadata.run("cd #{@load_path} && git remote add upstream #{write_url}")
          Simp::Metadata.run("cd #{@load_path} && git remote set-url upstream #{write_url}")
          exitcode = Simp::Metadata.run("cd #{@load_path} && git add -A && git commit -m '#{message}'; git push upstream master")
          if exitcode != 0
            Simp::Metadata.critical('error committing changes')
            raise exitcode.to_s
          else
            puts "Successfully updated #{name}"
          end
          self.dirty = false
        end
      end

      def load_from_dir(path)
        @load_path = path
        Dir.chdir(path) do
          Dir.glob('v1/**/*.yaml') do |filename|
            begin
              hash = YAML.load_file(filename)
              @data = deep_merge(@data, hash)
            end
          end
        end
        @releases = @data['releases'] unless @data['releases'].nil?
        @components = @data['components'] unless @data['components'].nil?
      end

      def deep_merge(target_hash, source_hash)
        source_hash.each do |key, value|
          if target_hash.key?(key)
            if value.class == Hash
              deep_merge(target_hash[key], value)
            else
              target_hash[key] = value
            end
          else
            target_hash[key] = value
          end
        end
        target_hash
      end

      def cleanup
        @cleanup.each do |path|
          FileUtils.rmtree(path)
        end
      end
    end
  end
end
