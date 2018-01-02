require 'simp/media'

module Simp
  module Media
    class Engine
      attr_accessor :options
      attr_accessor :input
      attr_accessor :output

      def debug2(output)
        Simp::Metadata.debug2(output)
      end

      def debug1(output)
        Simp::Metadata.debug1(output)
      end

      def info(output)
        Simp::Metadata.info(output)
      end

      def warning(output)
        Simp::Metadata.warning(output)
      end

      def error(output)
        Simp::Metadata.error(output)
      end

      def critical(output)
        Simp::Metadata.critical(output)
      end

      def initialize(options ={})
        {
            "input_type" => "internet",
            "input" => nil,
            "output_type" => "control_repo",
            "output" => "file:///usr/share/simp/control-repo",
            "url" => nil,
            "embed" => true,
            "license" => '/etc/simp/license.key',
            "sign" => false,
            "signing_key" => nil,
            "metadata" => nil,
            "branch" => "production",
            "destination_branch" => nil,
            "edition" => "community",
            "channel" => "stable",
            "flavor" => "default",
        }.each do |key, default_value|
          unless (options.key?(key))
            options[key] = default_value
          end
        end
        @cleanup = []
        @options = options
        @input = Module.const_get("Simp::Media::Type::#{@options["input_type"].capitalize}").new(options, self)
        @output = Module.const_get("Simp::Media::Type::#{@options["output_type"].capitalize}").new(options, self)
      end

      def run()
        # XXX ToDo: Need to not create a target_directory if an input directory exists
        if (@output.target_directory == nil)
          target = Dir.mktmpdir("cachedir")
          @cleanup << target
        else
          target = @output.target_directory
        end
        # XXX ToDo: this should all come from the bootstrap_source in the metadata engine
        metadata_components = [
            "enterprise-metadata",
            "simp-metadata"
        ]
        metadatapaths = []

        # XXX ToDo: only set this if input is specified
        @input.input_directory = @options["input"]
        # XXX ToDO: this loop should be abstracted to metadata

        metadata_components.each do |metadata|
          begin
            result = @input.fetch_component(metadata, { "target" => target})
            metadatapaths << result["path"]
          rescue Exception => ex
            puts ex
          end
        end

        if (metadatapaths == [])
          raise "Need one working metadata"
        end
        # XXX ToDo: Bring the engine creation up higher in the file since we now have bootstrap metadata
        metadata = Simp::Metadata::Engine.new(nil, metadatapaths)
        metadata.releases[@options["version"]].components.each do |component|
          retval = @input.fetch_component(component,{})
          @output.add_component(component, retval)
        end
        @output.finalize(nil)
        @input.cleanup
        @output.cleanup
        cleanup
      end
      def loaded?()
        true
      end
      def cleanup()
        @cleanup.each do |path|
          FileUtils.rmtree(path)
        end
      end
    end
  end
end