require_all "#{__dir__}"

module Simp
  module Metadata
    # Class to grab specific Repo details
    class Repo < Simp::Metadata::BuildHandler
      include Enumerable
      attr_accessor :engine
      attr_accessor :sources

      def initialize(engine, name, sources)
        @engine = engine
        @name = name
        @sources = sources
      end

      def to_s
        name
      end

      def name
        @name.to_s
      end

      def path_name
        name.tr('_', '-')
      end

      def output_filename
        name.sub('_', '-')
      end

      def binaryname
        "#{output_filename}-#{version}.#{extension}"
      end

      def data
        @sources.each do |name, data|
          @data = data if name == @name
        end
        @data
      end

      def get_from_data(item)
        data[item.to_sym]
      end

      def extension
        'tgz'
      end

      def keys
        %w[authoritative extension extract method primary source_type url]
      end

      def [](index)
        send index.to_sym
      end

      def each
        keys.each do |key|
          yield key, self[key]
        end
      end

      def compiled
        false
      end

      def compiled?
        compiled
      end

      def primary
        locations[:primary_source]
      end

      def url
        locations[:primary_source][:url]
      end

      def method
        locations[:primary_source][:method]
      end

      def extract
        locations[:primary_source][:extract]
      end

      def locations_array
        get_from_data('locations')
      end

      def primary_source
        value = {}
        locations_array.each { |location| value = location if location[:primary] }
        value
      end

      def version
        get_from_data('version') || ''
      end

      def locations
        {
          locations: locations_array,
          primary_source: primary_source
        }
      end

      def source_type
        get_from_data('source-type')
      end

      def authoritative?
        get_from_data('authoritative')
      end

      def authoritative
        get_from_data('authoritative')
      end
    end
  end
end
