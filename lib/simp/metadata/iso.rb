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
        retval = engine.sources[:bootstrap_metadata]
        engine.sources.each do |_name, source|
          next if source.isos.nil?
          if source.isos.key?(name)
            retval = source
            break
          end
        end
        retval
      end

      def get_from_iso
        iso_source.isos[name]
      end

      def size
        get_from_iso[:size]
      end

      def checksum
        get_from_iso[:checksum]
      end

      def primary
        get_from_iso[:primary]
      end

      def platform
        get_from_iso[:platform]
      end

      def dependencies
        result = {}
        engine.sources.each do |_name, source|
          next if source.isos.nil?
          source.isos.each do |image, data|
            next unless data[:platform] == platform
            result[image] = true
          end
        end
        if result.keys.size > 0
          result.keys
        else
          nil
        end
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
