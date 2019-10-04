module Simp
  module Metadata
    # Class for Puppet Versions
    class PuppetVersions
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

      def key?(name)
        keys.include?(name)
      end

      def keys
        result = {}
        if version.nil?
          engine.sources.each do |_name, source|
            source.isos.each do |_iso, data|
              result[data[:puppet_versions]] = true
            end
          end
        else
          engine.sources.each do |_name, source|
            if source.releases.key?(version)
              source.releases[version][:puppet_versions].each do |version, _data|
                result[version] = true
              end
            else
              source.release(version).each do |element, data|
                next unless element == 'puppet_versions'

                data.each { |version, _data| result[version] = true }
              end
            end
          end
        end
        result.keys
      end

      def output
        result = {}
        if version.nil?
          engine.sources.each do |_name, source|
            source.isos.each do |_iso, data|
              result[data[:puppet_versions]] = true
            end
          end
        else
          engine.sources.each do |_name, source|
            if source.releases.key?(version)
              source.releases[version][:puppet_versions].each do |version, data|
                result[version] = data.keys
              end
            else
              source.release(version).each do |element, data|
                next unless element == 'puppet_versions'

                data.each { |version, info| result[version] = info.keys }
              end
            end
          end
        end
        result.to_yaml
      end
    end
  end
end
