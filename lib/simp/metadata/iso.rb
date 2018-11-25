module Simp
  module Metadata
    class Iso
      include Enumerable
      attr_accessor :engine
      attr_accessor :release_version

      def initialize(engine, version, name)
        @engine = engine
        @name = name
        @release_version = version
        @platform = platform
      end

      def to_s
        name
      end

      def name
        @name
      end

      def iso_source
        retval = engine.sources['bootstrap_metadata']
        engine.sources.each do |_name, source|
          next if source.platforms.nil?
          source.platforms.each do |_platform, data|
            if data.key?(name)
              retval = data
              break
            end
          end
        end
        retval
      end

      def platform
        engine.sources.each do |_name, source|
          next if sources.platforms.nil?
          source.platforms.each do |platform, data|
            if data.keys.include?(name)
              platform.to_s
            end
          end
        end
      end

      def get_from_iso
        iso_source[name]
      end

      def size
        get_from_iso['size']
      end

      def checksum
        get_from_iso['checksum']
      end

      def primary
        get_from_iso['primary']
      end

      def dependencies
        result = {}
        data = engine.platforms[platform].keys
        return if data.keys.size == 1
        data.each do |dep|
          result[dep] = true unless dep == name
        end
        result
      end

      def keys
        %w(name size checksum platform primary dependencies)
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
