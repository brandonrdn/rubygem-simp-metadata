# vim: set noexpandtab ts=4 sw=4:
require 'tmpdir'
require 'simp/metadata'

module Simp
  module Metadata
    class Engine
      attr_accessor :sources

      def initialize(cachepath = nil, metadatarepos = [{:name => "simp-metadata", :url => 'https://github.com/simp/simp-metadata'}], edition = "community")
        @sources = {}
        @writable_source = "simp-metadata"
        priority = 0
        # XXX ToDo: Make a ticket to replace this with bootstrap_source info. nothing should need to pass metadatarepos into this engine unless they are overriding.
        metadatarepos.each do |repo|
          @sources[repo[:name]] = Simp::Metadata::Source.new(repo.merge({cachepath: cachepath, edition: edition, engine: self}))
        end
        bootstrap_source = Simp::Metadata::Bootstrap_source.new(edition)
        @sources[bootstrap_source.name] = bootstrap_source
      end

      def components()
        return Simp::Metadata::Components.new(self)
      end

      def releases()
        return Simp::Metadata::Releases.new(self)
      end

      def dirty?()
        dirty = false
        @sources.each do |name, source|
          if (source.dirty? == true)
            dirty = true
          end
        end
        dirty
      end

      def writable_source_name=(source)
        @writable_source = source
      end

      def writable_source_name()
        @writable_source
      end


      def writable_source()
        @sources[@writable_source]
      end

      def writable_url(metadata_name, url)
        @sources[metadata_name].write_url = url
      end

      def save(message = "Auto-saving using simp-metadata")
        Simp::Metadata.debug2("Saving metadata")
        @sources.each do |name, source|
          if (source.dirty? == true)
            Simp::Metadata.debug1("#{source} - dirty, saving")
            source.save(message)
          else
            Simp::Metadata.debug1("#{source} - clean, not saving")
          end
        end
      end

      def ssh_key
        @ssh_key
      end

      def ssh_key= (value)
        @ssh_key = value
      end

      def cleanup()
        @sources.each do |name, source|
          source.cleanup
        end
      end
    end
  end
end

