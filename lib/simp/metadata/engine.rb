# vim: set noexpandtab ts=4 sw=4:
require 'tmpdir'
require 'simp/metadata'

module Simp
  module Metadata
    # Main Engine Class
    class Engine
      attr_accessor :options, :sources, :component, :release, :ssh_key, :components

      def initialize(cachepath = nil, metadata_repos = {}, options = {})
        ENV['GIT_SSH'] = "#{File.dirname(__FILE__)}/git_ssh_wrapper.sh"
        ENV['SIMP_METADATA_SSHKEY'] = (options[:ssh_key]).to_s if options[:ssh_key]
        @options = options
        @metadata_repos = metadata_repos
        @component = options[:component]
        #@components = {}
        @writable_source = 'simp_metadata'.to_sym
        @cachepath = cachepath
        edition = options[:edition] || 'community'
        sources = Simp::Metadata::Sources.new(edition, @metadata_repos)
        @sources = sources.sources

        repos.keys.each do |key|
          repo = repos[key]
          source_hash = { name: key, source: repo }
          source_merge_options = { cachepath: cachepath, edition: edition, engine: self }
          new_source = Simp::Metadata::Source.new(source_hash.merge(source_merge_options))
          @sources[key] = new_source
          @sources.delete(:bootstrap_metadata)
        end

        #base_components.each do |key|
        #  component_name = key.to_s
        #  settings_hash = {}
        #  base_components[component_name].each do |setting, value|
        #    settings_hash[setting.to_sym] = value
        #  end
        #  @components[component_name] = settings_hash
        #end

        #@sources.each do |_source, source_data|
        #  source_data.components.each do |name, data|
        #    symbols_hash = data.inject({}){|memo, (k,v)| memo[k.gsub('-','_').to_sym] = v; memo}
        #    if @components[name]
        #      @components[name] = @components[name].merge(symbols_hash)
        #    else
        #      @components[name] = symbols_hash
        #    end
        #  end
        #end
      end

      def repos
        Simp::Metadata::Repos.new(@sources)
      end

      def components
        version ? release_components : base_components
      end

      def release_components
        Simp::Metadata::Components.new(self, @component, version)
      end

      def base_components
        Simp::Metadata::Components.new(self, @component, nil)
      end

      def platforms
        Simp::Metadata::Platforms.new(self)
      end

      def releases
        Simp::Metadata::Releases.new(self, options)
      end

      def isos
        Simp::Metadata::Isos.new(self)
      end

      def el_version
        options[:el_version]
      end

      def version
        options[:release]
      end

      def packages
        Simp::Metadata::Packages.new(self, version, el_version)
      end

      def dirty?
        dirty = false
        @sources.each do |_name, source|
          dirty = true if source.dirty?
        end
        dirty
      end

      def writable_source_name=(source)
        @writable_source = source
      end

      def writable_source_name
        @writable_source
      end

      def writable_source
        @sources[@writable_source]
      end

      def writable_url(metadata_name, url)
        @sources[metadata_name].write_url = url
      end

      def save(message = 'Auto-saving using simp-metadata')
        Simp::Metadata::Debug.debug2('Saving metadata')
        @sources.each do |_name, source|
          if source.dirty?
            Simp::Metadata::Debug.debug1("#{source} - dirty, saving")
            source.save(message)
          else
            Simp::Metadata::Debug.debug1("#{source} - clean, not saving")
          end
        end
      end

      def cleanup
        @sources.each { |_name, source| source.cleanup }
      end
    end
  end
end
