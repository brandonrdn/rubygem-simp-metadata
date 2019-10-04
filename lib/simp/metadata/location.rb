require 'uri'
module Simp
  module Metadata
    # Class for component location info
    class Location
      attr_accessor :location_info
      attr_accessor :location
      attr_accessor :component

      def initialize(location_info, location, component)
        @location_info = location_info
        @location = location
        @component = component
      end

      def to_s
        url
      end

      def primary
        if location.key?('primary')
          location['primary']
        else
          false
        end
      end

      def keys
        %w[extract primary method type url]
      end

      def [](index)
        send index.to_sym
      end

      def each
        keys.each do |key|
          yield key, self[key]
        end
      end

      def extract
        if location.key?('extract')
          location['extract']
        else
          false
        end
      end

      def method=(value)
        @local_method = value
      end

      def method
        if @local_method
          @local_method
        elsif location.key?('type')
          location['type'] == 'git' ? 'git' : 'file'
        else
          location.key?('method') ? location['method'] : 'file'
        end
      end

      def type
        location['binary']
      end

      def url=(value)
        @local_url = value
      end

      def url
        @local_url || real_url
      end

      def compiled_url
        if component.component_type == 'rubygem'
          case component.release_source.to_s
          when 'simp-metadata'
            "simp:///#{component.name}/#{component.binaryname}"
          when 'enterprise-metadata'
            "simp-enterprise:///#{component.name}/#{component.binaryname}"
          end
        end
      end

      def real_url
        output = nil
        output = compiled_url if component.compiled?
        if output.nil?
          if location.key?('url')
            output = location['url']
          elsif ['host', 'path', 'type'].all? { |value| location.key? value }
            output = "https://#{location['host']}/#{location['path']}"
          end
        end
        output
      end
    end
  end
end
