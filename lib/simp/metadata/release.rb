require 'simp/metadata/components'
module Simp
  module Metadata
    class Release
      attr_accessor :engine
      attr_accessor :version

      def initialize(engine, version)
        @engine = engine
        @version = version
      end

      def components(type = nil)
        Simp::Metadata::Components.new(engine, version, type)
      end

      def packages(type = nil)
        Simp::Metadata::Packages.new(engine, version, type)
      end

      def platforms
        Simp::Metadata::Platforms.new(engine, version)
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
        if options['type'] == 'simp-core'
          contents << "moduledir 'src'"
          contents << ''
          contents << puppetfile_component(components['simp-doc'], options)
          contents << "moduledir 'src/assets'"
          contents << ''
          components.each do |component|
            if component.component_type == 'rpm'
              contents << puppetfile_component(component, options)
            end
            if component.component_type == 'rubygem'
              contents << puppetfile_component(component, options)
            end
          end
          contents << "moduledir 'src/puppet/modules'"
          contents << ''
        end
        components.each do |component|
          if component.component_type == 'puppet-module'
            contents << puppetfile_component(component, options)
          end
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
          self_component_hash = {}
          comp.each do |key, value|
            if !attribute.nil?
              self_component_hash[key] = value.to_s if key.to_s == attribute
            else
              self_component_hash[key] = value.to_s
            end
            current_hash[comp.name] = self_component_hash
          end
        end

        compare_release.components.each do |comp|
          self_component_hash = {}
          comp.each do |key, value|
            if !attribute.nil?
              self_component_hash[key] = value.to_s if key.to_s == attribute
            else
              self_component_hash[key] = value.to_s
            end
            compare_hash[comp.name] = self_component_hash
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
    end
  end
end
