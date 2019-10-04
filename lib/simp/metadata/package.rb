module Simp
  module Metadata
    # Class for 3rd party packages utilized in SIMP builds
    class Package
      include Enumerable
      attr_accessor :engine, :release_version, :el_version, :name

      def initialize(engine, name, version, el_version)
        @engine = engine
        @name = name
        @release_version = version
        @el_version = el_version
      end

      def to_s
        name
      end

      def release_source
        retval = engine.sources[:bootstrap_metadata]
        engine.sources.each do |_name, source|
          if source.releases.key?(release_version)
            if source.packages[release_version][el_version].key?(name)
              retval = source
              break
            end
          elsif source.release(release_version).key?(name)
            retval = source
            break
          end
        end
        retval
      end

      def fetch_from_release
        retval = {}
        if release_source.releases.key?(release_version)
          if release_source.packages[release_version][el_version].key?(name)
            retval = release_source.packages[release_version][el_version][name]
          end
        elsif release_source.release(release_version).key?(name)
          retval = release_source.release(release_version)[name]
        end
        retval
      end

      def keys
        %w[rpm_name source version repo]
      end

      def [](index)
        send index.to_sym
      end

      def each
        keys.each do |key|
          yield key, self[key]
        end
      end

      def rpm_name
        fetch_from_release[:rpm_name]
      end

      def source
        fetch_from_release[:source]
      end

      def version
        rpm_name.scan(/[0-9]+[.][0-9]+[.][0-9]+/).join('')
      end

      def repo
        fetch_from_release[:repo]
      end

      def diff(package, attribute)
        diff = {}

        if attribute.nil?
          current_hash = {}
          comp_hash = {}
          each do |attr, value|
            current_hash.merge!(attr => value)
          end
          package.each do |attr, value|
            comp_hash.merge!(attr => value)
          end
          unless current_hash == comp_hash
            current_hash.each do |attr, value|
              if comp_hash[attr] != value
                diff[attr] = { 'original' => (current_hash[attr]).to_s, 'changed' => (comp_hash[attr]).to_s }
              end
            end
          end
          diff
        else
          v1 = self[attribute.to_s]
          v2 = package[attribute.to_s]
          unless v1 == v2
            diff[attribute] = { 'original' => v1.to_s, 'changed' => v2.to_s }
            diff
          end
        end
      end
    end
  end
end
