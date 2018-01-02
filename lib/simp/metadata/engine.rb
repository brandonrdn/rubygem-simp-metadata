# vim: set noexpandtab ts=4 sw=4:
require 'tmpdir'
require 'simp/metadata'

module Simp
	module Metadata
		class Engine
			attr_accessor :sources

			def initialize(cachepath = nil, metadatarepos = [ { :name => "simp-metadata", :url => 'https://github.com/simp/simp-metadata'} ], edition = "community")
				@sources = []
				@writable_source = "simp-metadata"
				priority = 0
				# XXX ToDo: Make a ticket to replace this with bootstrap_source info. nothing should need to pass metadatarepos into this engine unless they are overriding.
				metadatarepos.each do |repo|
					@sources[priority] = Simp::Metadata::Source.new(repo.merge({ cachepath: cachepath, edition: edition}))
					priority = priority + 1
				end
				@sources << Simp::Metadata::Bootstrap_source.new(edition)
			end

			def components()
				return Simp::Metadata::Components.new(self)
			end

			def releases()
				return Simp::Metadata::Releases.new(self)
			end

			def dirty?()
				dirty = false
				@sources.each do |source|
					if (source.dirty? == true)
						dirty = true
					end
				end
				dirty
			end

			def writable_source=(source)
				@writable_source = source
			end

			def writable_source()
				@writable_source
			end
      def writable_url(name, url)
				@sources.each do |source|
					if (source.name == name)
						source.write_url = url
					end
				end
			end
			def save()
				Simp::Metadata.debug2("Saving metadata")
				@sources.each do |source|
					if (source.dirty? == true)
						Simp::Metadata.debug1("#{source} - dirty, saving")
						source.save
					else
						Simp::Metadata.debug1("#{source} - clean, not saving")
					end
				end
			end

			def cleanup()
				@sources.each do |source|
					source.cleanup
				end
			end
		end
	end
end

