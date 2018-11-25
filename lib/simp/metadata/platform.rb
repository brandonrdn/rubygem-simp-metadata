module Simp
  module Metadata
    class Platform
      include Enumerable
      attr_accessor :release_version
      attr_accessor :engine
      attr_accessor :version

      def initialize(engine, version, platform)
        @engine = engine
        @release_version = version
        @platform = platform
      end

      def name
        @platform
      end

      def platform_source
        retval = engine.sources['bootstrap_metadata']
        engine.sources.each do |_name, source|
          next if source.platforms.nil?
          if source.platforms.key?(name)
            retval = source
            break
          end
        end
        retval
      end

      def images
        images = {}
        hash = platform_source.platforms[name]
        hash.each do |iso, _data|
          images[iso] = true
        end
        images.keys
      end

      def to_s
        name
      end

      def keys
        %w(images)
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
