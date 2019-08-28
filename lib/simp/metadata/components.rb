module Simp
  module Metadata
    class Components
      include Enumerable
      attr_accessor :engine
      attr_accessor :version
      attr_accessor :type

      def initialize(engine, component = nil, version = nil, type = nil)
        @engine = engine
        @version = version
        @type = type
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
        Simp::Metadata::Component.new(engine, index, version)
      end

      def key?(name)
        keys.include?(name)
      end

      def keys
        result = {}
        if version.nil?
          engine.sources.each do |_source_name, source_data|
            if @component
              result[@component] = true if source_data.components.key?(@component)
            else
              source_data.components.keys.each { |name| result[name] = true }
            end
          end
        else
          engine.sources.each do |_name, source|
            if source.releases.key?(version)
              if @component
                result[@component] = true if source.releases[version].key?(@component)
              else
                source.releases[version].each { |component, _data| result[component] = true }
              end
            else
              source.release(version).each do |element, data|
                if element == 'components'
                  if @component
                    result[@component] = true if data.key?(@component)
                  else
                    data.each { |component, _data| result[component] = true }
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
