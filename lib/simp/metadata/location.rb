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
        self.url
      end

      def primary
        if (location.key?("primary"))
          location["primary"]
        else
          false
        end
      end

      def keys()
        ["extract","primary","method","type","url"]
      end

      def [] (index)
        self.send index.to_sym
      end

      def each(&block)
        self.keys.each do |key|
          yield key, self[key]
        end
      end

      def extract
        if (location.key?("extract"))
          location["extract"]
        else
          false
        end
      end

      def method
        if (location.key?("type"))
          if (location["type"] == "git")
            method = "git"
          else
            method = "file"
          end
        else
          if (location.key?("method"))
            location["method"]
          else
           method = "file"
          end
        end
      end

      def type
        location["binary"]
      end

      def url
        base = self.real_url
        uri = URI(base)
        if (uri.scheme == "simp-enterprise")
            if (uri.query.class == String)
              query_elements = uri.query.split("&")
              newquery = []
              found_version = false
              found_filetype = false
              query_elements.each do |element|
                elements = element.split("=")
                if (elements.size > 1)
                  if (elements[0] == "version")
                    found_version = true
                    elements[1] = component.version
                    newquery << elements.join("=")
                  elsif (elements[0] == "filetype")
                    found_filetype = true
                    elements[1] = component.extension
                    newquery << elements.join("=")
                  else
                    newquery << element
                  end
                else
                  newquery << element
                end
              end
              if (found_version == false)
                newquery << "version=#{component.version}"
              end
              if (found_filetype == false)
                newquery << "filetype=#{component.extension}"
              end
              uri.query = newquery.join("&")
            end
            uri.to_s
        else
          case component.component_type
            when "rubygems"
              if (base =~ /.*\.gem/)
              else
                "#{base}/#{component.asset_name}-#{component.version}.gem"
              end
          end
          base
        end
      end

      def real_url
        if (location.key?("url"))
          location["url"]
        else
          if (location.key?("host"))
            if (location.key?("path"))
              if (location.key?("type"))
                "https://#{location["host"]}/#{location["path"]}"
              end
            end
          end
        end
      end


    end
  end
end
