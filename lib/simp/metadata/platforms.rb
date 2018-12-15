module Simp
  module Metadata
    class Platforms
      include Enumerable
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :type
      attr_accessor :metadata_version

      def initialize(engine, version = nil)
        @engine = engine
        @version = version
      end

      def to_s
        keys.to_s
      end

      def each
        keys.each do |version|
          yield self[version]
        end
      end

      def [](index)
        Simp::Metadata::Platform.new(engine, version, index)
      end

      def key?(name)
        keys.include?(name)
      end

      def keys
        result = {}
        if version.nil?
          engine.sources.each do |_name, source|
            source.isos.each do |name, data|
              result[data['platform']] = true
            end
          end
        else
          engine.sources.each do |_name, source|
            if source.releases.key?(version)
              source.releases[version]['platforms'].each do |platform, _data|
                result[platform] = true
              end
            else
              source.release(version).each do |element, data|
                if element == 'platforms'
                  data.each do |platform, _data|
                    result[platform] = true
                  end
                end
              end
            end
          end
        end
        result.keys
      end


    end
  end
end