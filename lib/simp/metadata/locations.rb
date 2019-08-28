module Simp
  module Metadata
    class Locations
      include Enumerable
      attr_accessor :location_info
      attr_accessor :component

      def initialize(location_info, component)
        @location_info = location_info
        @component = component
      end

      def data
        if location_info['locations'].nil?
          [location_info['primary_source']] + location_info['mirrors']
        else
          location_info['locations']
        end
      end

      def to_s
        data.to_s
      end

      def size
        data.size
      end

      def each
        data.each_index do |location|
          yield self[location]
        end
      end

      def [](location)
        Simp::Metadata::Location.new(location_info, data[location], component)
      end

      def primary
        retval = find(&:primary)
        if retval.nil?
          if location_info.key?('primary_source')
            retval = Simp::Metadata::Location.new(location_info, location_info['primary_source'], component)
          else
            retval = first
          end
        end
        retval
      end
    end
  end
end
