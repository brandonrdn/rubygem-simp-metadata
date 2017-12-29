require 'fileutils'
module Simp
  module Media
    module Type
      class Local < Simp::Media::Type::Base
        def input_directory=(directory)
          @input_directory = directory
        end
        def input_directory
          @options["input"]
        end
        def fetch_component(component, options)
          retval = {}

          case component.class.to_s
            when "String"
              retval["path"] = "#{options["input"]}/simp/metadata/#{component.name}"
            when "Simp::Metadata::Component"
              # XXX ToDo: Add manifest.yaml support so we don't need this logic at all
              case component.component_type
                when "documentation"
                  subdirectory = "simp/docs"
                when "puppet-module"
                  subdirectory = "simp/modules"
                else
                  subdirectory = "simp/assets"
              end

              retval["path"] = "#{options["input"]}/#{subdirectory}/#{component.name}"
          end
          return retval
        end
      end
    end
  end
end
