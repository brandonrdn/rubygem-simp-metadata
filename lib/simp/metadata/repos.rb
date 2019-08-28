module Simp
  module Metadata
    class Repos
      include Enumerable
      attr_accessor :engine, :edition, :args, :sources

      def initialize(sources, edition = 'community')
        @sources = sources
        @engine = engine
        @edition = edition
      end

      def to_s
        keys.to_s
      end

      def each
        keys.each do |key|
          yield self[key]
        end
      end

      def [](index)
        Simp::Metadata::Repo.new(engine, index, sources)
      end

      def key?(name)
        keys.include?(name)
      end

      def keys
        result = {}
        sources.each do |name, _data|
          result[name] = true
        end
        result.keys
      end

      #def create(name, settings = {})
      #  unless key?(name)
      #    engine.writable_source.sources[name] = settings
      #    engine.writable_source.dirty = true
      #  end
      #end

    end
  end
end
