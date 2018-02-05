
require 'open3'

module Simp
  module Media
    module Type
      class Internet < Simp::Media::Type::Base
        attr_accessor :options
        def initialize(options, engine)
          @cleanup = []
          super(options, engine)
        end

        def input_directory=(directory)
            @input_directory = directory
        end
        def input_directory
          if (@input_directory == nil)
            target = Dir.mktmpdir("cachedir")
            @cleanup << target
            @input_directory = target
          else
            @input_directory
          end
        end
        def fetch_component(component, options)
          Simp::Metadata.download_component(component, options.merge({"target" => self.input_directory}))
        end

        def cleanup()
          @cleanup.each do |path|
            FileUtils.rmtree(path)
          end
        end
      end
    end
  end
end
