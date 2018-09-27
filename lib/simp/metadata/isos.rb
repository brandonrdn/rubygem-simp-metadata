module Simp
  module Metadata
    class Isos
      include Enumerable
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :type
      attr_accessor :iso

      def initialize(engine)
        @engine = engine
      end

      def to_s
        keys.to_s
      end

      def iso
        iso
      end

      def each
        keys.each do |version|
          yield self[version]
        end
      end

      def [](iso)
        Simp::Metadata::Iso.new(iso, iso_data(iso), platform_data(iso))
      end

      def key?(name)
        keys.include?(name)
      end

      def images
        engine.isos.keys
      end

      def iso_data(iso)
        result = {}
        data_hash.each do |platform, images|
          if iso.nil?
            result[platform] = images
          else
            images.each do |image, data|
              if image == iso
                result[image] = data
              end
            end
          end
        end
        result
      end

      def platform_data(iso)
        result = {}
        data_hash.each do |platform, images|
          images.each do |image, _data|
            if image == iso
              result[platform] = images
            end
          end
        end
        result
      end

      def keys
        result = {}
        data_hash.each do |_platform, images|
          images.each do |iso, _data|
            result[iso] = true
          end
        end
        result.keys
      end

      def data_hash
        hash = {}
        engine.sources.each do |_name, source|
          source.isos.each do |platform, data|
            images = []
            data.each do |name|
              images.push(name)
            end
            hash[platform] = images
          end
        end
        hash
      end

    end
  end
end