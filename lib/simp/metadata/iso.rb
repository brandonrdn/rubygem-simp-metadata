module Simp
  module Metadata
    # Class for ISO information
    class Iso
      include Enumerable
      attr_accessor :engine, :release_version, :name

      def initialize(engine, version, name)
        @engine = engine
        @name = name
        @release_version = version
      end

      def to_s
        name
      end

      def name
        @name
      end

      def iso_source
        retval = engine.sources[:simp_metadata]
        engine.sources.each do |_name, source|
          next if source.isos.nil?

          if source.isos.key?(name)
            retval = source
            break
          end
        end
        retval
      end

      def fetch_from_iso(item)
        iso_source.isos[name][item.to_s]
      end

      def size
        fetch_from_iso(:size)
      end

      def checksum
        fetch_from_iso(:checksum)
      end

      def primary
        fetch_from_iso(:primary)
      end

      def platform
        fetch_from_iso(:platform)
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
        result.keys unless result.empty?
      end

      def keys
        %w[name size checksum platform primary dependencies]
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
