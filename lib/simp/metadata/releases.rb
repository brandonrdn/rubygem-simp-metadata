require 'simp/metadata/release'

module Simp
  module Metadata
    class Releases
      include Enumerable
      attr_accessor :engine

      def initialize(engine)
        @engine = engine
      end

      def each
        keys.each do |version|
          yield self[version]
        end
      end

      def [](index)
        Simp::Metadata::Release.new(engine, index)
      end

      def keys
        result = {}
        engine.sources.each do |_name, source|
          source.releases.keys.each do |name|
            result[name] = true
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

      def create(destination, source = 'master')
        engine.sources.each do |_name, metadata_source|
          if metadata_source.writable?
            metadata_source.create_release(destination, source)
          end
        end
      end
    end
  end
end
