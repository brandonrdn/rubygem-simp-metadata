module Simp
  module Metadata
    class Isos
      include Enumerable
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :type
      attr_accessor :iso

      def initialize(engine, version = nil)
        @engine = engine
        @release_version = version
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

      def platforms
        platforms = []
        if version.nil?
          engine.isos.keys.each do |iso, data|
            platforms[data] = true
          end
        else
          platforms = engine.releases[release_version]['isos']['platforms']
        end
        platforms
      end

      def key?(name)
        keys.include?(name)
      end

      def images
        images = []
        if version.nil?
        engine.isos.keys.each do |platform, data|
          data.each{|image| puts image }
        end


        end
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

      def keys
        result = {}
        if version.nil?
          engine.sources.each do |_name, source|
            source.isos.each do |platform, data|
              data.each do |name, _value|
              result[name] = true
              end
            end
          end
        else
          platforms.each do |platform|
            engine.releases[version]['isos']
          end
          engine.sources.each do |_name, source|
            if source.releases.key?(version)
              source.releases[version]['isos'].each do |_platform, data|
                data.each { |name| result[name] = true }
              end
            else
              source.release(version).each do |element, data|
                if element == 'isos'
                  data.each do |_platform, data|
                    data.each { |name| result[name] = true }
                  end
                end
              end
            end
          end
        end
        result.keys
      end

=begin
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
=end

    end
  end
end