require 'simp/metadata/release'

module Simp
  module Metadata
    # Class to manage SIMP releases on upstream repos
    class Releases
      include Enumerable
      attr_accessor :engine

      def initialize(engine, options)
        @engine = engine
        @options = options
        @release = options[:release]
      end

      def each
        keys.each do |version|
          yield self[version]
        end
      end

      def [](index)
        Simp::Metadata::Release.new(engine, index, @options)
      end

      def keys
        result = {}
        engine.sources.each do |_name, source|
          if @release
            result[@release] = true if source.releases.key?(@release)
          else
            source.releases.keys.each { |name| result[name] = true }
          end
        end
        result.keys
      end

      def size
        keys.size
      end

      def to_s
        keys.to_s
      end

      def delete(version)
        engine.sources.each do |_name, metadata_source|
          metadata_source.delete_release(version) if metadata_source.writable?
        end
      end

      def create(dest, source = 'master')
        engine.sources.each do |_name, metadata_source|
          metadata_source.create_release(dest, source) if metadata_source.writable?
        end
      end
    end
  end
end
