# vim: set noexpandtab ts=4 sw=4:
require 'tmpdir'
require 'simp/metadata'

module Simp
  module Metadata
    class Engine
      attr_accessor :options
      attr_accessor :sources

      def initialize(cachepath = nil, metadatarepos = nil, edition = 'community', options = {})
        ENV['GIT_SSH'] = "#{File.dirname(__FILE__)}/git_ssh_wrapper.sh"
        unless options['ssh_key'].nil?
          ENV['SIMP_METADATA_SSHKEY'] = (options['ssh_key']).to_s
        end
        @options = options
        @sources = {}
        @writable_source = 'simp-metadata'
        priority = 0
        bootstrap_source = Simp::Metadata::Bootstrap_source.new(edition)
        if metadatarepos.class.to_s == 'Hash'
          metadatarepos.each do |reponame, url|
            url_matches = [/https?:/,/git@gitlab.onyxpoint.com:/]
            if url.match?(Regexp.union(url_matches))
              method = 'git'
              extract = false
            else
              method = 'file'
              extract = true
            end
            # XXX: ToDo replace with better logic once Simp::Metadata.download_component gets refactored.
            # MUCH LAYERING VIOLATIONS
            next unless bootstrap_source.components.key?(reponame)
            bootstrap_source.components[reponame]['locations'][0]['url'] = url
            bootstrap_source.components[reponame]['locations'][0]['method'] = method
            bootstrap_source.components[reponame]['locations'][0]['extract'] = extract
          end
        end
        @sources[bootstrap_source.name] = bootstrap_source
        components.keys.each do |key|
          component = components[key]
          @sources[key] = Simp::Metadata::Source.new({ name: key, component: component }.merge(cachepath: cachepath, edition: edition, engine: self))
        end
      end

      def components
        Simp::Metadata::Components.new(self)
      end

      def isos
        Simp::Metadata::Isos.new(self)
      end

      def releases
        Simp::Metadata::Releases.new(self)
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
        Simp::Metadata.debug2('Saving metadata')
        @sources.each do |_name, source|
          if source.dirty?
            Simp::Metadata.debug1("#{source} - dirty, saving")
            source.save(message)
          else
            Simp::Metadata.debug1("#{source} - clean, not saving")
          end
        end
      end

      attr_reader :ssh_key

      attr_writer :ssh_key

      def cleanup
        @sources.each do |_name, source|
          source.cleanup
        end
      end
    end
  end
end
