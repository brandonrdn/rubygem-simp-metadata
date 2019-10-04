require 'simp/media'

module Simp
  module Media
    # Media Engine Class
    class Engine
      attr_accessor :options
      attr_accessor :input
      attr_accessor :output

      def debug2(output)
        Simp::Metadata::Debug.debug2(output)
      end

      def debug1(output)
        Simp::Metadata::Debug.debug1(output)
      end

      def info(output)
        Simp::Metadata::Debug.info(output)
      end

      def warning(output)
        Simp::Metadata::Debug.warning(output)
      end

      def error(output)
        Simp::Metadata::Debug.error(output)
      end

      def critical(output)
        Simp::Metadata::Debug.critical(output)
      end

      def initialize(options = {})
        {
          'input_type' => 'internet',
          'input' => nil,
          'output_type' => 'control_repo',
          'output' => 'file:///usr/share/simp/control-repo',
          'url' => nil,
          'embed' => true,
          'license' => '/etc/simp/license.key',
          'sign' => false,
          'signing_key' => nil,
          'metadata' => nil,
          'branch' => 'production',
          'destination_branch' => nil,
          'edition' => 'community',
          'channel' => 'stable',
          'flavor' => 'default'
        }.each do |key, default_value|
          options[key] = default_value unless options.key?(key)
        end
        @cleanup = []
        @options = options
        raise 'input_type must be specified' if options[:input_type].nil?
        raise 'output_type must be specified' if options[:output_type].nil?

        @input = Module.const_get("Simp::Media::Type::#{@options[:input_type].capitalize}").new(options, self)
        @output = Module.const_get("Simp::Media::Type::#{@options[:output_type].capitalize}").new(options, self)
      end

      def run
        # TODO: Need to not create a target_directory if an input directory exists
        if @output.target_directory.nil?
          target = Dir.mktmpdir('cachedir')
          @cleanup << target
        end

        # TODO: only set this if input is specified
        @input.input_directory = @options[:input]

        metadata = Simp::Metadata::Engine.new(nil, nil, @options)
        version = @options[:version]
        metadata.releases[version].components.each do |component|
          info("Adding #{component.name}")
          retval = @input.fetch_source(component, {})
          @output.add_component(component, retval)
        end
        @output.finalize(nil)
        @input.cleanup
        @output.cleanup
        cleanup
      end

      def loaded?
        true
      end

      def cleanup
        @cleanup.each do |path|
          FileUtils.rmtree(path)
        end
      end
    end
  end
end
