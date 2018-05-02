module Simp
  module Metadata
    class Buildinfo
      include Enumerable
      attr_accessor :type
      attr_accessor :component

      def initialize(component, type)
        @type = type
        @component = component
      end

      def keys()
        ["type", "build_method"]
      end

      def [] (index)
        self.send index.to_sym
      end

      def each(&block)
        self.keys.each do |key|
          yield key, self[key]
        end
      end

      def fetch_data
        component.fetch_data("buildinfo")
      end

      def method_defaults
        {
            "rpm" => {
                "build_method" => "simp-core",
            }
        }
      end

      def build_method()
        buildinfo = self.fetch_data
        if (buildinfo == nil)
          retval = method_defaults[type]["build_method"]
        else
          if (buildinfo.key?(type))
            if (buildinfo[type].key?("build_method"))
              retval = buildinfo[type]["build_method"]
            else
              retval = method_defaults[type]["build_method"]
            end
          else
            retval = method_defaults[type]["build_method"]
          end
        end
        return retval
      end
    end
  end
end