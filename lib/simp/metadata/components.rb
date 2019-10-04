module Simp
  module Metadata
    # Class for SIMP Components
    class Components
      include Enumerable
      attr_accessor :engine
      attr_accessor :version

      def initialize(engine, component = nil, version = nil)
        @engine = engine
        @version = version
        @component = component
      end

      def to_s
        keys.to_s
      end

      def size
        keys.size
      end

      def each
        keys.each do |key|
          yield self[key]
        end
      end

      def [](index)
        if version
          unless engine.releases[version].components.key?(index)
          end
        else
          unless engine.components.key?(index)
            Simp::Metadata::Debug.abort("Test2")
          end
        end
        Simp::Metadata::Component.new(engine, index, version)
      end

      def key?(name)
        keys.include?(name)
      end

      def keys
        result = {}
        if version.nil?
          engine.sources.each do |_source_name, source_data|
            source_data.components.keys.each { |name| result[name] = true }
          end
        else
          engine.sources.each do |_name, source|
            if source.releases.key?(version)
              source.releases[version].each { |component, _data| result[component] = true }
            else
              source.release(version).each do |element, data|
                next unless element == 'components'

                data.each { |component, _data| result[component] = true }
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
