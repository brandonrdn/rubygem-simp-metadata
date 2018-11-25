module Simp
  module Metadata
    class Package
      include Enumerable
      attr_accessor :engine
      attr_accessor :release_version

      def initialize(engine, name, version)
        @engine = engine
        @name = name
        @release_version = version
      end

      def to_s
        name
      end

      def name(type = 'package')
        @name
      end

      def package_source
        retval = engine.sources['bootstrap_metadata']
        engine.sources.each do |_name, source|
          next if source.packages.nil?
          if source.packages.key?(name)
            retval = source
            break
          end
        end
        retval
      end

      def release_source
        retval = engine.sources['bootstrap_metadata']
        engine.sources.each do |_name, source|
          if source.releases.key?(release_version)
            if source.releases[release_version]['packages'].key?(name)
              retval = source
              break
            end
          else
            if source.release(release_version).key?(name)
              retval = source
              break
            end
          end
        end
        retval
      end

      #
      # Will be used to grab method based data in the future, rather
      # then calling get_from_release or get_from_package directly,
      #
      # For now, just use it in Simp::Metadata::Buildinfo
      def fetch_data(item)
        package = get_from_package
        release = get_from_release
        platform = get_from_platform
        if release.key?(item)
          release[item]
        else
          package[item]
        end
      end

      def get_from_package
        package_source.packages[name]
      end

      def get_from_release
        retval = {}
        if release_source.releases.key?(release_version)
          if release_source.releases[release_version]['packages'].key?(name)
            retval = release_source.releases[release_version]['packages'][name]
          end
        else
          if release_source.release(release_version).key?(name)
            retval = release_source.release(release_version)[name]
          end
        end
        retval
      end

      def keys
        %w(rpm_name, url, version, revision)
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
        get_from_release['rpm_name']
      end

      def url
        get_from_release['source']
      end

      def version
        rpm_name.scan(/[0-9]+[.][0-9]+[.][0-9]+/).to_s
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
              diff[attr] = {'original' => (current_hash[attr]).to_s,
                            'changed' => (comp_hash[attr]).to_s} if comp_hash[attr] != value
            end
          end
          diff
        else
          v1 = self[attribute.to_s]
          v2 = package[attribute.to_s]
          unless v1 == v2
            diff[attribute] = {'original' => v1.to_s, 'changed' => v2.to_s}
            diff
          end
        end
      end
      
    end
  end
end
