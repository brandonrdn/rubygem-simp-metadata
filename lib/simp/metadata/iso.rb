module Simp
  module Metadata
    class Iso
      include Enumerable
      attr_accessor :release_version
      attr_accessor :data
      attr_accessor :name

      def initialize(name, data, platform_data)
        @name = name
        @data = data
        @platform_data = platform_data
      end

      def name
        @name
      end

      def image
        @name
      end

      def data
        @data
      end

      def to_s
        name
      end

      def platform_data
        @platform_data
      end

      def primary
        get_from_data['primary']
      end

      # def fetch_data(item)
      #   result = []
      #   data.each do |kernel, array|
      #     array.each do |hash|
      #       hash.each do |key, value|
      #       if key == item
      #         result.push(value)
      #       end
      #       end
      #     end
      #   end
      #   result
      # end

      def get_from_data
        data[name]
      end

      def keys
        %w(image size checksum name platform dependencies)
      end

      def [](index)
        send index.to_sym
      end

      def each
        keys.each do |key|
          yield key, self[key]
        end
      end

      def iso_data(iso)
        data[name].each do |set|
          set.each do |key,value|
            if key == name
              if name == iso
                set
              end
            end
          end
        end
      end

      def platform
        get_from_data['platform']
      end

      def size
        get_from_data['size']
      end

      def checksum
        get_from_data['checksum']
      end

      def dependencies
        result = {}
        platform_data.each do |platform, images|
          images.each do |img, data|
            unless img == image
              if data['primary'].nil?
              result[img] = true
              end
            end
          end
        end
        result.keys unless result.empty?
      end

    end
  end
end
