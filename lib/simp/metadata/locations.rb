module Simp
  module Metadata
    class Locations
      include Enumerable
      attr_accessor :locationinfo
      attr_accessor :component

      def initialize(locationinfo, component)
        @locationinfo = locationinfo
        @component = component
      end

      def data
        if locationinfo['locations'].nil?
          [locationinfo['primary_source']] + locationinfo['mirrors']
        else
          locationinfo['locations']
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
        Simp::Metadata::Location.new(locationinfo, data[location], component)
      end

      def primary
        retval = find(&:primary)
        if retval.nil?
          if locationinfo.key?('primary_source')
            retval = Simp::Metadata::Location.new(locationinfo, locationinfo['primary_source'], component)
          else
            retval = first
          end
        end
        retval
      end
    end
  end
end
