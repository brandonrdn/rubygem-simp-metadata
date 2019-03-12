module Simp
  module Metadata
    class Platform
      include Enumerable
      attr_accessor :release_version
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :metadata_version

      def initialize(engine, version, platform)
        @engine = engine
        @release_version = version
        @platform = platform
      end

      def name
        @platform
      end

      def key?(name)
        keys.include?(name)
      end

      def images
        hash = {}
        retval = engine.sources['bootstrap_metadata']
        engine.sources.each do |_name, source|
          next if source.isos.nil?
          source.isos.each do |iso,data|
            if data['platform'] == name
            hash[iso] = data
          end
          end
        end
        hash.keys
      end

      def to_s
        name
      end

      def keys
        images
      end

      def [](index)
        send index.to_sym
      end

      def each
        keys.each do |key|
          yield key, self[key]
        end
      end

    end
  end
end
