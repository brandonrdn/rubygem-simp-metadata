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

      def puppetfile_component(component, options)
        contents = []
        contents << "mod '#{component.name}',"
        contents << "  :git => '#{component.primary.url}',"
        if (component.ref == nil)
          contents << "  :tag => '#{component.tag}'"
        else
          contents << "  :ref => '#{component.ref}'"
        end
        contents << ""
        contents
      end

      def puppetfile(options = {})
        contents = []
        if (options["type"] == "simp-core")
          contents << "moduledir 'src'"
          contents << ""
          contents << puppetfile_component(components['simp-doc'], options)
          contents << puppetfile_component(components['simp-rsync'], options)
          contents << "moduledir 'src/assets'"
          contents << ""
          components.each do |component|
            if (component.component_type == "rpm")
              contents << puppetfile_component(component, options)
            end
          end
          contents << "moduledir 'src/rubygems'"
          contents << ""
          components.each do |component|
            if (component.component_type == "rubygem")
              contents << puppetfile_component(component, options)
            end
          end
          contents << "moduledir 'src/puppet/modules'"
          contents << ""
        end
        components.each do |component|
          if (component.component_type == "puppet-module")
            contents << puppetfile_component(component, options)
          end
        end
        contents.join("\n")
      end

      def to_s()
        self.components.to_s
      end

      def diff(compare_release, attribute)
        diff = {}

        current_hash = {}
        compare_hash = {}
        self.components.each do |comp|
          self_component_hash = {}
          comp.each do |key, value|
            if (attribute != nil)
              if (key.to_s == attribute)
                self_component_hash[key] = value.to_s
              end
            else
              self_component_hash[key] = value.to_s
            end
            current_hash[comp.name] = self_component_hash
          end
        end

        compare_release.components.each do |comp|
          self_component_hash = {}
          comp.each do |key, value|
            if (attribute != nil)
              if (key.to_s == attribute)
                self_component_hash[key] = value.to_s
              end
            else
              self_component_hash[key] = value.to_s
            end
            compare_hash[comp.name] = self_component_hash
          end
        end
        current_hash.each do |comp, hash|

          diff_hash = {}
          hash.each do |key, value|
            if (compare_hash.key?(comp))
              if (compare_hash[comp][key] != value)
                diff_hash[key] = {
                    "original" => "#{value}",
                    "changed" => "#{compare_hash[comp][key]}"
                }
              end
            end
          end
          unless diff_hash.empty?
            diff[comp] = diff_hash
          end
        end
        return diff
      end
    end
  end
end
