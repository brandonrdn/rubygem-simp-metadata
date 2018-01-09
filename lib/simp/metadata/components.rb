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

      def to_s()
        self.keys.to_s
      end

      def size()
        self.keys.size
      end

      def each(&block)
        self.keys.each do |version|
          yield self[version]
        end
      end

      def [](index)
        Simp::Metadata::Component.new(engine, index, version)
      end

      def key?(name)
        self.keys.include?(name)
      end

      def keys()
        result = {}
        if (version == nil)
          engine.sources.each do |name, source|
            source.components.keys.each do |name|
              result[name] = true
            end
          end
        else
          engine.sources.each do |name, source|
            if (source.releases.key?(version))
              source.releases[version].each do |component, data|
                  result[component] = true
              end
            else
              source.release(version).each do |component, data|
                result[component] = true
              end
            end
          end
        end
        result.keys
      end

      def create(name, settings = {})
        unless (self.key?(name))
          engine.writable_source.components[name] = settings
          engine.writable_source.dirty = true
        end
      end
    end
  end
end

