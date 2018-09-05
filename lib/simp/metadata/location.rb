require 'uri'
module Simp
  module Metadata
    class Location
      attr_accessor :locationinfo
      attr_accessor :location
      attr_accessor :component

      def initialize(locationinfo, location, component)
        @locationinfo = locationinfo
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
        %w(extract primary method type url)
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
        else
          if location.key?('type')
            if location['type'] == 'git'
              'git'
            else
              'file'
            end
          else
            if location.key?('method')
              location['method']
            else
              'file'
            end
          end
        end
      end

      def type
        location['binary']
      end

      def url=(value)
        @local_url = value
      end

      def url
        if @local_url
          @local_url
        else
          base = real_url
          uri = Simp::Metadata.uri(base)
          case uri.scheme
          when 'simp-enterprise'
            if uri.query.class == String
              query_elements = uri.query.split('&')
              newquery = []
              found_version = false
              found_filetype = false
              query_elements.each do |element|
                elements = element.split('=')
                if elements.size > 1
                  if elements[0] == 'version'
                    found_version = true
                    elements[1] = component.version
                    newquery << elements.join('=')
                  elsif elements[0] == 'filetype'
                    found_filetype = true
                    elements[1] = component.extension
                    newquery << elements.join('=')
                  else
                    newquery << element
                  end
                else
                  newquery << element
                end
              end
              newquery << "version=#{component.version}" unless found_version

              unless found_filetype
                newquery << "filetype=#{component.extension}"
              end

              uri.query = newquery.join('&')
            end
            uri.to_s

          when 'simp'
            if uri.query.class == String
              query_elements = uri.query.split('&')
              newquery = []
              found_version = false
              found_filetype = false
              query_elements.each do |element|
                elements = element.split('=')
                if elements.size > 1
                  if elements[0] == 'version'
                    found_version = true
                    elements[1] = component.version
                    newquery << elements.join('=')
                  elsif elements[0] == 'filetype'
                    found_filetype = true
                    elements[1] = component.extension
                    newquery << elements.join('=')
                  else
                    newquery << element
                  end
                else
                  newquery << element
                end
              end
              newquery << "version=#{component.version}" unless found_version
              unless found_filetype
                newquery << "filetype=#{component.extension}"
              end
              uri.query = newquery.join('&')
            end
            uri.to_s
          else
            case component.component_type
            when 'rubygem'
              if base =~ /.*\.gem/
              else
                "#{base}/#{component.asset_name}-#{component.version}.gem"
              end
            end
            base
          end
        end
      end

      def real_url
        if component.compiled?
          case component.component_type
          when 'rubygem'
            case component.release_source.to_s
            when 'simp-metadata'
              return "simp:///#{component.name}/#{component.binaryname}"
            when 'enterprise-metadata'
              return "simp-enterprise:///#{component.name}/#{component.binaryname}"
            end
          end
        end
        if location.key?('url')
          location['url']
        else
          if location.key?('host')
            if location.key?('path')
              if location.key?('type')
                "https://#{location['host']}/#{location['path']}"
              end
            end
          end
        end
      end
    end
  end
end
