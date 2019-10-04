module Simp
  module Metadata
    # 3rd Party Packages Class
    class Packages
      include Enumerable
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :el_version

      def initialize(engine, version = nil, el_version = nil)
        @engine = engine
        @version = version
        @el_version = el_version
      end

      def to_s
        keys.to_s
      end

      def size
        keys.size
      end

      def each
        keys.each do |version|
          yield self[version]
        end
      end

      def [](index)
        Simp::Metadata::Package.new(engine, index, version, el_version)
      end

      def key?(name)
        keys.include?(name)
      end

      def keys
        result = {}
        engine.sources.each do |_name, source|
          if source.releases.key?(version)
            source.packages[version][el_version].each do |package, _data|
              result[package] = true
            end
          else
            source.release(version).each do |element, data|
              next unless element == 'packages'

              data.each do |package, _data|
                result[package] = true
              end
            end
          end
        end
        result.keys
      end
    end
  end
end
