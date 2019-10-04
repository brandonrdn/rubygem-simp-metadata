module Simp
  module Metadata
    # Build Info Class
    class Buildinfo
      include Enumerable
      attr_accessor :type
      attr_accessor :component

      def initialize(component, type)
        @type = type
        @component = component
      end

      def keys
        %w[type build_method]
      end

      def [](index)
        send index.to_sym
      end

      def each
        keys.each do |key|
          yield key, self[key]
        end
      end

      def fetch_data
        component.fetch_data('buildinfo')
      end

      def method_defaults
        { rpm: { build_method: 'simp-core' } }
      end

      def build_method
        buildinfo = fetch_data
        if buildinfo && buildinfo[type].key?(:buildinfo)
          buildinfo[type][:build_method]
        else
          method_defaults[type][:build_method]
        end
      end
    end
  end
end
