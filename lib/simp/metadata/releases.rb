require 'simp/metadata/release'

module Simp
  module Metadata
    class Releases
      include Enumerable
      attr_accessor :engine

      def initialize(engine)
        @engine = engine
      end

      def each(&block)
        self.keys.each do |version|
          yield self[version]
        end
      end

      def [](index)
        Simp::Metadata::Release.new(engine, index)
      end

      def keys()
        result = {}
        engine.sources.each do |source|
          source.releases.keys.each do |name|
            result[name] = true
          end
        end
        result.keys
      end

      def size()
        self.keys.size
      end

      def to_s()
        self.keys.to_s
      end
    end
  end
end

