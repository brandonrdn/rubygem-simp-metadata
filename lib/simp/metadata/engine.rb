# vim: set noexpandtab ts=4 sw=4:
require 'tmpdir'
require 'simp/metadata'

module Simp
	module Metadata
		class Engine
			attr_accessor :sources

			def initialize(cachepath = nil, metadatarepos = [ 'https://github.com/simp/simp-metadata'])
				@sources = []
				priority = 0
				metadatarepos.each do |repo|
					@sources[priority] = Simp::Metadata::Source.new(repo, cachepath)
					priority = priority + 1
				end
				@sources << Simp::Metadata::Bootstrap_source.new()
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

			def save()
				@sources.each do |source|
					if (source.dirty? == true)
						source.save
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

