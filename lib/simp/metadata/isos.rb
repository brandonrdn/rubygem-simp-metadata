module Simp
  module Metadata
    class Isos
      include Enumerable
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :type
      attr_accessor :platform

      def initialize(engine, platform = nil, version = nil)
        @engine = engine
        @version = version
        @platform = platform
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
        engine.sources.each do |_name, source|
          source.platforms.each do |name, data|
            if platform.nil?
              data.each do |iso, _data|
                result[iso] = true
              end
            else
              if @platform == name
                data.each do |iso, _data|
                  result[iso] = true
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
