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

      def data()
        if (self.locationinfo["locations"] != nil)
          self.locationinfo["locations"]
        else
          [ self.locationinfo["primary_source"] ] + self.locationinfo["mirrors"]
        end
      end

      def to_s()
        self.data.to_s
      end

      def size()
        self.data.size
      end

      def each(&block)
          self.data.each_index do |location|
            yield self[location]
          end
      end

      def [](location)
        Simp::Metadata::Location.new(locationinfo,data[location], component)
      end

      def primary

        retval = self.find { |i| i.primary == true }
        if (retval == nil)
          if (self.locationinfo.key?("primary_source"))
            retval = Simp::Metadata::Location.new(self.locationinfo, self.locationinfo["primary_source"], component)
          else
            retval = self.first
          end
        end
        return retval
      end
    end
  end
end

