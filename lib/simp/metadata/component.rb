require_relative "#{__dir__}/build_handler.rb"
module Simp
  module Metadata
    # Class used to grab component information, both static and release-based
    class Component < Simp::Metadata::BuildHandler
      include Enumerable
      attr_accessor :engine
      attr_accessor :release_version

      def initialize(engine, name, version)
        @engine = engine
        @name = name
        @release_version = version
        if @release_version
          unless engine.releases[@release_version].components.key?(@name)
            Simp::Metadata::Debug.critical("Component #{@name} does not exist in release #{@release_version}")
          end
        else
          unless engine.components.key?(@name)
            Simp::Metadata::Debug.critical("Component #{@name} does not exist")
          end
        end
      end

      def to_s
        name
      end

      def name(type = 'component')
        case type
        when 'component'
          @name.to_s
        when 'puppetfile'
          if module_name
            module_name
          else
            if component_type == 'rubygem'
              "rubygem-#{@name.to_s.tr('-', '_')}"
            elsif component_type == 'puppet-module'
              @name.gsub(/pupmod-/, '').to_s
            else
              @name.to_s
            end
          end
        else
          puts type
          Simp::Metadata::Debug.abort("Expected type to be 'component' or 'puppetfile'")
        end
      end

      def options
        @engine.options
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
          if source.release(release_version).key?(name)
            retval = source
            break
          end
        end
        retval
      end

      def fetch_data(item)
        component = grab_from_component
        release = grab_from_release
        if !release || !component
          nil
        else
          if release.key?(item)
            release[item]
          else
            component[item]
          end
        end
      end

      def grab_from_component
        component_source.components[name]
      end

      def grab_from_release
        if release_source.release(release_version).empty?
          {}
        else
          release_source.release(release_version)[name] if release_source.release(release_version).key?(name)
        end
      end

      def type
        fetch_data('type')
      end

      def extension
        if real_extension.nil?
          case component_type
          when 'simp-metadata', 'puppet-module'
            'tgz'
          when 'logstash-filter', 'rubygem'
            'gem'
          when 'grafana-plugin'
            'zip'
          else
            ''
          end
        else
          real_extension
        end
      end

      def keys
        %w[
          component_type authoritative package_name module_name extension format module_name type
          url method extract branch tag ref version target revision rpm_name
        ]
      end

      def data_hash
        data_keys = keys - ['release_source','component_source']
        result = {}
        data_keys.each do |key|
          value = self[key]
          result[key.to_s] = value.to_s
        end
        result
      end

      def data_array
        result = []
        data_hash.each do |_key, value|
          result.push(value)
        end
        result
      end

      def key_gsub(key)
        if keys.include?(key)
          key
        else
          if keys.include?(key.gsub('-','_'))
            key.gsub('-','_')
          else
            Simp::Metadata::Debug.abort("Unrecognized Component key: #{key}")
          end
        end
      end

      def [](index)
        item = key_gsub(index)
        send item.to_sym
      end

      def each
        keys.each do |key|
          yield key, self[key]
        end
      end

      def real_extension
        fetch_data('extension')
      end

      def module_name
        fetch_data('module-name') || @name
      end

      def package_name
        if fetch_data('package-name')
          fetch_data('package-name')
        else
          case component_type
          when 'puppet-module'
            @name =~ /pupmod-*/ ? @name : "pupmod-#{@name}"
          when 'rubygem'
            @name =~ /rubygem-*/ ? @name : "rubygem-#{@name}"
          else
            @name
          end
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
        # TODO: Allow manifest.yaml to override locations
        # TODO: Use primary_source and mirrors here if locations is empty
        infohash = {
          'locations' => fetch_data('locations'),
          'primary_source' => fetch_data('primary_source'),
          'mirrors' => fetch_data('mirrors')
        }
        Simp::Metadata::Locations.new(infohash, self)
      end

      # TODO: Generate a filename, and output file type; ie, directory or file

      def format
        fetch_data('format')
      end

      def component_type
        fetch_data('component-type')
      end

      def authoritative?
        fetch_data('authoritative')
      end

      def authoritative
        fetch_data('authoritative')
      end

      def deprecated
        fetch_data('deprecated')
      end

      def deprecated?
        deprecated
      end

      def revision
        revision = fetch_data('revision')
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
            release[name] = { 'revision' => value }
          end
        end
        release_source.dirty = true
      end

      def ref
        fetch_data('ref')
      end

      def ref=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          if release.key?(name)
            release[name]['ref'] = value
          else
            release[name] = { 'ref' => value }
          end
        end
        release_source.dirty = true
      end

      def branch
        fetch_data('branch')
      end

      def branch=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          release.key?(name) ? release[name]['branch'] = value : release[name] = { 'branch' => value }
        end
        release_source.dirty = true
      end

      def tag
        fetch_data('tag')
      end

      def tag=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          release.key?(name) ? release[name]['tag'] = value : release[name] = { 'tag' => value }
        end
        release_source.dirty = true
      end

      def version
        ver = ''
        %w[version tag ref branch].each do |item|
          unless grab_from_release[item].nil?
            ver = grab_from_release[item]
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
              exitcode == 0
            end
          end
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
        elsif !revision
          component_version
        else
          "#{component_version}-#{revision}"
        end
      end

      def target
        target = fetch_data('target')
        if target.nil?
          'noarch'
        else
          target
        end
      end

      def target=(value)
        release = release_source.releases[release_version]
        unless release.nil?
          release.key?(name) ? release[name]['target'] = value : release[name] = { 'target' => value }
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
          "#{package_name}-#{rpm_version}.#{target}.rpm"
        elsif compiled?
          "#{package_name}-#{rpm_version}.#{os_version}.#{target}.rpm"
        else
          "#{package_name}-#{rpm_version}.#{target}.rpm"
        end
      end

      def compiled?
        if grab_from_release.key?('compiled')
          grab_from_release['compiled']
        else
          false
        end
      end

      def binaryname
        "#{package_name}-#{version}.#{extension}"
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
          #buildinfo_hash = {}
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

      def create(component, settings = { 'ref' => nil })
        begin
          engine.sources.each do |_name, metadata_source|
            if metadata_source.writable?
              engine.metadata_source
            else
              engine.releases[options[:release]].components[component] = settings
            end
          end
        rescue StandardError => e
          Simp::Metadata::Debug.critical("Unable to create #{component} for #{options[:release]} release")
          Simp::Metadata::Debug.abort(e.message)
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
              if comp_hash[attr] != value
                diff[attr] = { 'original' => (current_hash[attr]).to_s, 'changed' => (comp_hash[attr]).to_s }
              end
            end
          end
          diff
        else
          v1 = self[attribute.to_s]
          v2 = component[attribute.to_s]
          unless v1 == v2
            diff[attribute] = { 'original' => v1.to_s, 'changed' => v2.to_s }
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
        rpm_builder = Simp::Metadata::RpmBuild.new(@engine, @release_version, name, options)
        rpm_builder.component_rpm_build(name, destination)
      end

      def enterprise_paths
        [
          "#{base_enterprise_path}/products/simp-enterprise/#{module_name}",
          "#{base_enterprise_path}/products/simp-enterprise-dev/#{module_name}"
        ]
      end

      def download_source(src = nil, file = rpm_name)
        output = nil
        sources = if src
                    [src]
                  else
                    component_source.to_s == 'enterprise-metadata' ? enterprise_paths : community_paths
                  end
        sources.each do |source|
          case source
          when /^https?:/
            file_check = `curl -sLI #{source}/#{file} | head -n 1 | awk '{print $2}'`.chomp
            if file_check == '200'
              output = source
              break
            end
          else
            output = source if File.exist?("#{source}/#{file}")
            break
          end
        end
        output
      end

      def download(destination, src = nil, file = rpm_name)
        source = src || download_source(nil, rpm_name)
        downloader(source, file, destination)
      end
    end
  end
end
