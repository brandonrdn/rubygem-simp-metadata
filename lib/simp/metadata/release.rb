require 'simp/metadata/components'
module Simp
  module Metadata
    # Class for Release information
    class Release
      attr_accessor :engine
      attr_accessor :version

      def initialize(engine, version, options = {})
        @engine = engine
        @version = version
        @options = options
      end

      def components
        Simp::Metadata::Components.new(engine, @options[:component], version)
      end

      def platforms
        Simp::Metadata::Platforms.new(engine, version)
      end

      def puppet_versions
        Simp::Metadata::PuppetVersions.new(engine, version)
      end

      def isos
        Simp::Metadata::Isos.new(engine, version)
      end

      def puppetfile_component(component, _options)
        contents = []
        contents << "mod '#{component.name('puppetfile')}',"
        contents << "  :git => '#{component.primary.url}',"
        contents << if component.tag.nil?
                      "  :ref => '#{component.ref}'"
                    else
                      "  :tag => '#{component.tag}'"
                    end
        contents << ''
        contents
      end

      def puppetfile(options = {})
        contents = []
        if options[:type] == 'simp-core'
          contents << "moduledir 'src'"
          contents << ''
          contents << puppetfile_component(components['simp-doc'], options)
          contents << "moduledir 'src/assets'"
          contents << ''
          components.each do |component|
            case component.component_type
            when 'asset', 'rubygem', 'rpm'
              contents << puppetfile_component(component, options)
            end
          end
          contents << "moduledir 'src/puppet/modules'"
          contents << ''
        end
        components.each do |component|
          contents << puppetfile_component(component, options) if component.component_type == 'puppet-module'
        end
        contents.join("\n")
      end

      def to_s
        components.to_s
      end

      def diff(compare_release, attribute)
        diff = {}
        current_hash = {}
        compare_hash = {}
        components.each do |comp|
          self_comp_hash = {}
          comp.each do |key, value|
            self_comp_hash[key] = value.to_s
            self_comp_hash.delete_if { |k, _v| k.to_s == attribute }
            current_hash[comp.name] = self_comp_hash
          end
        end

        compare_release.sources.each do |comp|
          self_comp_hash = {}
          comp.each do |key, value|
            self_comp_hash[key] = value.to_s
            self_comp_hash.delete_if { |k, _v| k.to_s == attribute }
            compare_hash[comp.name] = self_comp_hash
          end
        end
        current_hash.each do |comp, hash|
          diff_hash = {}
          hash.each do |key, value|
            next unless compare_hash.key?(comp)
            next unless compare_hash[comp][key] != value

            diff_hash[key] = {
              'original' => value.to_s,
              'changed' => (compare_hash[comp][key]).to_s
            }
          end
          diff[comp] = diff_hash unless diff_hash.empty?
        end
        diff
      end

      def add_component(component, hash)
        unless engine.sources.key?(component)
          Simp::Metadata::Debug.warning("#{component} is not a recognized SIMP Component")
          Simp::Metadata::Debug.warning("Please use `simp-metadata component add` if this is a valid component")
          Simp::Metadata::Debug.abort("#{component} is not a recognized SIMP Component.")
        end
        Simp::Metadata::Debug.abort("#{component} is already part of SIMP #{version}") if components.key?(component)
        engine.writable_source.releases[version][component] = hash
        engine.writable_source.dirty = true
      end

      def delete_component(component)
        if components.key?(component)
          engine.writable_source.releases[version].delete(component)
          engine.writable_source.dirty = true
        end
      end
    end
  end
end
