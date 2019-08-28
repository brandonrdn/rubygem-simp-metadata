require 'yaml'
require 'uri'
require 'fileutils'

module Simp
  module Metadata
    # Set source information
    class Source
      attr_accessor :assets, :basename, :cache_path, :components, :data, :edition, :engine, :isos,
                    :name, :packages, :platforms, :releases, :url

      def initialize(args)
        unless args.key?(:engine)
          raise ':engine must be specified when initializing a metadata source'
        end
        unless args.key?(:name)
          raise ':name must be specified when initializing a metadata source'
        end
        unless args.key?(:source)
          raise ':component must be specified when initializing a metadata source'
        end
        unless args.key?(:edition)
          raise ':edition must be specified when initializing a metadata source'
        end

        @engine = args[:engine]
        @name = args[:name]
        @source = args[:source]
        @edition = args[:edition]
        @url = args[:url] ? args[:url] : @source.sources[@name][:locations][0][:url]
        @write_url = @url
        @components = {}
        @releases = {}
        @assets = {}
        @packages = {}
        @cache_path = cache_path(@url)
        @data = {}
        @isos = {}
        @platforms = {}
        @cleanup = []
        @options = @engine.options
        options = @options.merge({target: @cache_path})

        retval = Simp::Metadata.download_source(@source, options)
        load_from_dir(retval[:path])

        @dirty = false
      end

      def upstream_owner(url)
        url.to_s.split('/')[-2].to_s.split(':')[-1]
      end

      def cache_path(url)
        cache_edition = url =~ /enterprise/ ? 'enterprise' : 'community'
        "#{base_cache_dir}/simp-metadata/#{cache_edition}/#{upstream_owner(url)}"
      end

      def base_cache_dir
        ENV.fetch('XDG_CACHE_HOME', "#{ENV['HOME']}/.cache")
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
          FileUtils.rm_r("#{@cache_path}/#{@source.name}")
          retval = Simp::Metadata.download_source(@source, target: @cache_path, 'url' => value)
          load_from_dir(retval[:path])
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
        #ToDo: Find a way to specify which files are dirty, rather than writing all of them each time
        if dirty?
          # Save components.yaml
          File.open("#{@load_path}/v1/components.yaml", 'w') { |f| f.write({ 'components' => @components }.to_yaml) }

          # Save release files
          prereleases = [/.*-[Aa][Ll][Pp][Hh][Aa].*/, /.*-[Bb][Ee][Tt][Aa].*/, /.*-[Rr][Cc].*/]
          @releases.each do |release_name, data|
            directory = case release_name
                        when *prereleases
                          'prereleases'
                        when /^nightly-/
                          'nightlies'
                        when /unstable/
                          'channels'
                        when /^test-/
                          'tests'
                        else
                          'releases'
                        end
            FileUtils.mkdir_p("#{@load_path}/v1/#{directory}")
            new_file_content = { 'releases' => { release_name.to_s => data } }.to_yaml
            File.open("#{@load_path}/v1/#{directory}/#{release_name}.yaml", 'w') { |file| file.write(new_file_content) }
          end
          Dir.chdir(@load_path) do
            upstream_name = upstream_owner(write_url)

            # Add upstream if needed
            exit_code = Simp::Metadata.run("git remote -v | grep #{upstream_name}")
            Simp::Metadata.run("git remote add #{upstream_name} #{write_url}") if exit_code == 0

            commit_push_command = "git add -A && git commit -m '#{message}'; git push #{upstream_name} master"
            exit_code = Simp::Metadata.run(commit_push_command)
            if exit_code == 0
              puts "Successfully updated #{name}"
            else
              Simp::Metadata.critical('error committing and pushing changes')
              raise exit_code.to_s
            end
          end
          self.dirty = false
        end
      end
=begin
          # ToDo: Write files to yaml, commit and push (where appropriate)
          Simp::Metadata.run("cd #{@load_path} && rm -rf v1")
          FileUtils.mkdir_p("#{@load_path}/v1")
          File.open("#{@load_path}/v1/components.yaml", 'w') { |file| file.write({ 'components' => @components }.to_yaml) }
          prereleases = [/.*-[Aa][Ll][Pp][Hh][Aa].*/, /.*-[Bb][Ee][Tt][Aa].*/, /.*-[Rr][Cc].*/]
          @releases.each do |release_name, data|
            directory = case release_name
                        when *prereleases
                          'prereleases'
                        when /^nightly-/
                          'nightlies'
                        when /unstable/
                          'channels'
                        when /^test-/
                          'tests'
                        else
                          'releases'
                        end
            FileUtils.mkdir_p("#{@load_path}/v1/#{directory}")
            File.open("#{@load_path}/v1/#{directory}/#{release_name}.yaml", 'w') { |file| file.write({ 'releases' => { release_name.to_s => data } }.to_yaml) }
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
=end

      def load_from_dir(path)
        @load_path = path
        Dir.chdir(path) do
          Dir.glob('**/*.yaml') do |filename|
            begin
              # If savable, load all files, otherwise, load only used files to prevent engine from being too stacked
              if @options[:save]
                hash = YAML.load_file(filename)
                @data = deep_merge(@data, hash)
              elsif filename.match?(Regexp.union([/components.yaml/, /#{@options[:release]}/]))
                hash = YAML.load_file(filename)
                @data = deep_merge(@data, hash)
              end
            end
          end
        end
        @releases = @data['releases'] unless @data['releases'].nil?
        @components = @data['components'] unless @data['components'].nil?
        @assets = @data['assets'] unless @data['assets'].nil?
        @packages = @data['packages'] unless @data['packages'].nil?
        @isos = @data['isos'] unless @data['isos'].nil?
        @platforms = @data['platforms'] unless @data['platforms'].nil?
        remove_instance_variable(:@data)
      end

      def deep_merge(target_hash, source_hash)
        source_hash.each do |key, value|
          if target_hash.key?(key)
            value.class == Hash ? deep_merge(target_hash[key], value) : target_hash[key] = value
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
