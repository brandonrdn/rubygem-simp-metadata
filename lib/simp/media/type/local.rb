require 'fileutils'
module Simp
  module Media
    module Type
      class Local < Simp::Media::Type::Base
        attr_writer :input_directory

        def input_directory
          @options['input']
        end

        def fetch_component(component, options)
          retval = {}

          case component.class.to_s
          when 'String'
            retval['path'] = "#{options['input']}/simp/metadata/#{component.name}"
          when 'Simp::Metadata::Component'
            # XXX ToDo: Add manifest.yaml support so we don't need this logic at all
            subdirectory = case component.component_type
                           when 'documentation'
                             'simp/docs'
                           when 'puppet-module'
                             'simp/modules'
                           else
                             'simp/assets'
                           end
            retval['path'] = "#{options['input']}/#{subdirectory}/#{component.name}"
          end
          retval
        end
      end
    end
  end
end
