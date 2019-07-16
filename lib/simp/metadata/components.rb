module Simp
  module Metadata
    class Components
      include Enumerable
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :type

      def initialize(engine, version = nil, type = nil)
        @engine = engine
        @version = version
        @type = type
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
        Simp::Metadata::Component.new(engine, index, version)
      end

      def key?(name)
        keys.include?(name)
      end

      def keys
        result = {}
        if version.nil?
          engine.sources.each do |_name, source|
            source.components.keys.each do |name|
              result[name] = true
            end
          end
        else
          engine.sources.each do |_name, source|
            if source.releases.key?(version)
              source.releases[version].each do |component, _data|
                result[component] = true
              end
            else
              source.release(version).each do |element, data|
                if element == 'components'
                  data.each do |component, _data|
                    result[component] = true
                  end
                end
              end
            end
          end
        end
        result.keys
      end

      def create(name, settings = {})
        unless key?(name)
          engine.writable_source.components[name] = settings
          engine.writable_source.dirty = true
        end
      end

    end
  end
end
