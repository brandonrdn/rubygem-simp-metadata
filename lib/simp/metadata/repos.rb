module Simp
  module Metadata
    # Default Repos Class to parse sources
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
    end
  end
end
