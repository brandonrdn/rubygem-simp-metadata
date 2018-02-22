# vim: set noexpandtab ts=4 sw=4:
require 'tmpdir'
require 'simp/metadata'

module Simp
  module Metadata
    class Engine
      attr_accessor :sources

      def initialize(cachepath = nil, metadatarepos = nil, edition = "community", options = {})

        ENV['GIT_SSH'] = "#{File.dirname(__FILE__)}/git_ssh_wrapper.sh"
        if (options["ssh_key"] != nil)
          ENV['SIMP_METADATA_SSHKEY'] = "#{options["ssh_key"]}"
        end
        @sources = {}
        @writable_source = "simp-metadata"
        priority = 0
        bootstrap_source = Simp::Metadata::Bootstrap_source.new(edition)
        if (metadatarepos.class.to_s == "Hash")
          metadatarepos.each do |reponame, url|
            # XXX: ToDo replace with better logic once Simp::Metadata.download_component gets refactored.
            # MUCH LAYERING VIOLATIONS
            if (bootstrap_source.components.key?(reponame))
              bootstrap_source.components[reponame]["locations"][0]["url"] = url
              bootstrap_source.components[reponame]["locations"][0]["method"] = "git"
              bootstrap_source.components[reponame]["locations"][0]["extract"] = false
            end
          end
        end
        @sources[bootstrap_source.name] = bootstrap_source
        self.components.keys.each do |key|
          component = self.components[key]
          @sources[key] = Simp::Metadata::Source.new({:name => key, :component => component}.merge({cachepath: cachepath, edition: edition, engine: self}))
        end
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

