module Simp
  module Metadata
    class Component < BuildHandler
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

      def name(type = 'component')
        case type
        when 'component'
          @name.to_s
        when 'puppetfile'
          if component_type == 'rubygem'
            "rubygem-#{@name.to_s.tr('-', '_')}"
          elsif component_type == 'puppet-module'
            @name.gsub(/pupmod-/, '').to_s
          else
            @name.to_s
          end
        else
          abort(Simp::Metadata.critical("Expected type to be 'component' or 'puppetfile'")[0])
        end
      end

      def component_source
        retval = engine.sources[:simp_metadata]
        engine.sources.each do |_name, source|
          next if source.components.nil?
          if source.components.key?(name)
            retval = source
            break
          end
        end
        retval
      end

      def release_source
        retval = engine.sources[:simp_metadata]
        engine.sources.each do |_name, source|
          if source.releases.key?(release_version)
            if source.releases[release_version].key?(name)
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

      # Will be used to grab method based data in the future, rather
      # then calling get_from_release or get_from_component directly,
      #
      # For now, just use it in Simp::Metadata::Buildinfo
      def fetch_data(item)
        component = get_from_component
        release = get_from_release
        if release.key?(item)
          release[item]
        else
          component[item]
        end
      end

      def get_from_component
        component_source.components[name]
      end

      def get_from_release
        retval = {}
        if release_source.releases.key?(release_version)
          if release_source.releases[release_version].key?(name)
            retval = release_source.releases[release_version][name]
          end
        else
          if release_source.release(release_version).key?(name)
            retval = release_source.release(release_version)[name]
          end
        end
        retval
      end

      def type
        get_from_component['type']
      end

      def extension
        if real_extension.nil?
          case component_type
          when 'simp-metadata'
            'tgz'
          when 'logstash-filter'
            'gem'
          when 'rubygem'
            'gem'
          when 'grafana-plugin'
            'zip'
          when 'puppet-module'
            'tgz'
          else
            ''
          end
        else
          real_extension
        end
      end

      def keys
        %w(component_type authoritative asset_name extension format module_name type url method extract branch tag ref version release_source component_source target revision)
      end

      def [](index)
        send index.to_sym
      end

      def each
        keys.each do |key|
          yield key, self[key]
        end
      end

      def real_extension
        get_from_component['extension']
      end

      def real_asset_name
          get_from_component['component-name']
      end

      def module_name
        asset_name
      end

      def asset_name
        if real_asset_name.nil?
          case component_type
          when 'puppet-module'
            split = name.split('-')
            split[split.size - 1]
          else
            name
          end
        else
          real_asset_name
        end
      end

      def output_type
        if compiled?
          :file
        else
          :directory
        end
      end

      def output_filename
        if compiled?
          "#{name}-#{version}.#{extension}"
        else
          name
        end
      end

      def primary
        locations.primary
      end

      def url
        locations.primary.url
      end

      def method
        locations.primary.method
      end

      def extract
        locations.primary.extract
      end

      def locations
        # ToDo: Allow manifest.yaml to override locations
        # ToDo: Use primary_source and mirrors here if locations is empty
        infohash = {
            'locations' => get_from_component['locations'],
            'primary_source' => get_from_component['primary_source'],
            'mirrors' => get_from_component['mirrors']
        }
        Simp::Metadata::Locations.new(infohash, self)
      end

      # ToDo: Generate a filename, and output file type; ie, directory or file

      def format
        get_from_component['format']
      end

      def component_type
        get_from_component['component-type']
      end

      def authoritative?
        get_from_component['authoritative']
      end

      def authoritative
        get_from_component['authoritative']
      end

      def deprecated
        get_from_component['deprecated']
      end

      def deprecated?
        deprecated
      end

      def revision
        revision = get_from_release['revision']
        if revision.nil?
          '0'
        elsif !revision
          nil
        else
          revision
        end
      end

      def revision=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          if release.key?(name)
            release[name]['revision'] = value
          else
            release[name] = {'revision' => value}
          end
        end
        release_source.dirty = true
      end

      def ref
        get_from_release['ref']
      end

      def ref=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          if release.key?(name)
            release[name]['ref'] = value
          else
            release[name] = {'ref' => value}
          end
        end
        release_source.dirty = true
      end

      def branch
        get_from_release['branch']
      end

      def branch=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          if release.key?(name)
            release[name]['branch'] = value
          else
            release[name] = {'branch' => value}
          end
        end
        release_source.dirty = true
      end

      def tag
        get_from_release['tag']
      end

      def tag=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          if release.key?(name)
            release[name]['tag'] = value
          else
            release[name] = {'tag' => value}
          end
        end
        release_source.dirty = true
      end

      def version
        ver = ''
        %w(version tag ref branch).each do |item|
          unless get_from_release[item].nil?
            ver = get_from_release[item]
            break
          end
        end
        ver
      end

      def version?
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            system("git clone #{url} > /dev/null 2>&1")
            Dir.chdir("./#{module_name}") do
              exitcode = Simp::Metadata.run("git checkout #{version} > /dev/null 2>&1")
              if exitcode == 0
                true
              else
                false
              end
            end
          end
        end
      end

      def rpm_basename
        if component_type == 'puppet-module'
          if asset_name =~ /pupmod-*/
            asset_name
          else
            "pupmod-#{asset_name}"
          end
        elsif component_type == 'rubygem'
          if asset_name =~ /rubygem-*/
            asset_name
          else
            "rubygem-#{asset_name}"
          end
        else
          asset_name
        end
      end

      def component_version
        if version =~ /^[v][0-9]/
          version.split('v')[1]
        else
          version
        end
      end

      def rpm_version
        if component_version =~ /^[0-9]+.[0-9]+.[0-9]+.[0-9]+/
          component_version
        else
          if !revision
            component_version
          else
            "#{component_version}-#{revision}"
          end
        end
      end

      def target
        target = get_from_release['target']
        if target.nil?
          'noarch'
        else
          target
        end
      end

      def target=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          if release.key?(name)
            release[name]['target'] = value
          else
            release[name] = {'target' => value}
          end
        end
        release_source.dirty = true
      end

      def os_version
        os_version = engine.options[:os_version]
        if os_version.nil?
          'el7'
        else
          os_version
        end
      end

      def rpm_name
        if component_type == 'puppet-module'
          "#{rpm_basename}-#{rpm_version}.#{target}.rpm"
        else
          if compiled?
            "#{rpm_basename}-#{rpm_version}.#{os_version}.#{target}.rpm"
          else
            "#{rpm_basename}-#{rpm_version}.#{target}.rpm"
          end
        end
      end

      def compiled?
        if get_from_release.key?('compiled')
          get_from_release['compiled']
        else
          false
        end
      end

      def binaryname
        "#{asset_name}-#{version}.#{extension}"
      end

      def view(attribute)
        comp = self
        view_hash = {}
        if attribute.nil?
          comp.each do |key, value|
            view_hash[key] = value.to_s unless value.nil? || value == ''
          end
          location_hash = {}
          comp.locations.each do |location|
            location.each do |key, value|
              location_hash.merge!(key => value.to_s) unless value.nil?
            end
          end
          buildinfo_hash = {}
          comp.buildinfo.each do |buildinfo|
            # Needs to be fixed/added to
            buildinfo.each do |_key, _value|
            end
          end
          view_hash['location'] = location_hash
        else
          view_hash[attribute] = comp[attribute].to_s
        end
        view_hash
      end

      def create(component, settings={'ref' => nil})

        begin
          engine.sources.each do |_name, metadata_source|
            if metadata_source.writable?
              engine.metadata_source
            else
              engine.releases[options[:release]].components[component] = settings
            end
            end
          rescue
            Simp::Metadata.critical("Unable to create #{component} for #{options[:release]} release")
            exit 6
          end
        end


      def diff(component, attribute)
        diff = {}

        if attribute.nil?
          current_hash = {}
          comp_hash = {}
          each do |attr, value|
            current_hash.merge!(attr => value)
          end
          component.each do |attr, value|
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
          v2 = component[attribute.to_s]
          unless v1 == v2
            diff[attribute] = {'original' => v1.to_s, 'changed' => v2.to_s}
            diff
          end
        end
      end

      def buildinfo(type = nil)
        if type.nil?
          {}
        else
          Simp::Metadata::Buildinfo.new(self, type)
        end
      end

      def build(destination)
        component_rpm_build(name, destination)
      end

      def enterprise_paths
        [
            "#{base_enterprise_path}/products/simp-enterprise/#{module_name}",
            "#{base_enterprise_path}/products/simp-enterprise-dev/#{module_name}"
        ]
      end

      def download_source(src = nil, file = rpm_name)
        output = nil
        if src
          sources = [src]
        else
          sources = component_source.to_s == 'enterprise-metadata' ? enterprise_paths : community_paths
        end
        sources.each do |source|
          if source =~ /^https?:/
            file_check = `curl -sLI #{source}/#{file} | head -n 1 | awk '{print $2}'`.chomp
            if file_check == '200'
              output = source
              break
            end
          elsif File.exist?("#{source}/#{file}")
            output = source
            break
          end
        end
        output
      end

      def download(destination, src = nil, file = rpm_name)
        source = src ? src : download_source(nil, rpm_name)
        downloader(source, file, destination)
      end
    end
  end
end
