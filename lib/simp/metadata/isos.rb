module Simp
  module Metadata
    class Isos
      include Enumerable
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :type

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
        Simp::Metadata::Iso.new(engine, version, index)
      end

      def key?(name)
        keys.include?(name)
      end

      def keys
        result = {}
        if version.nil?
          engine.sources.each do |_name, source|
            source.isos.each do |name, _data|
              result[name] = true
            end
          end
        else
          engine.sources.each do |_name, source|
            next if source.isos.keys.size < 1
            platforms = source.releases[version]['platforms'].keys
            platforms.each do |platform|
              engine.platforms[platform].images.each do |name, _data|
                result[name] = true
              end
            end
          end
        end
        result.keys
      end

    end
  end
end
