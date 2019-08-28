require 'cgi'
require_relative '../commands'

module Simp
  module Metadata
    module Commands
      # Search Class for finding components via attribute values
      class Search < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root

        def description
          'Search for components based on attributes'
        end

        def options
          defaults(argv) do |opts, _options|
            opts.banner = "Usage: simp-metadata search <attribute>=<value>"
            opts.banner << "  #{description}"
            opts.banner << "  - supports multiple attributes as well as encoded URLs"
          end
        end

        def data
          data = {}
          @argv.each do |argument|
            split = argument.split('=')
            name = split[0]
            value = split[1]
            data[name] = value
          end
          data
        end

        def grab_results
          results = {}
          @engine.sources.each do |component|
            result = data.all? do |key, value|
              if key == 'url'
                component.locations.any? do |location|
                  location.url == value || location.url == CGI.unescape(value)
                end
              else
                component[key] == value || component[key] == CGI.unescape(value)
              end
            end
            results[component.name] = true if result
          end
          results.keys.empty? ? nil : results.keys
        end

        def data_check
          exit(Simp::Metadata.warning('No search parameters specified')[0]) if (data == {}) || data.nil?
          data.each { |k, v| exit(Simp::Metadata.info("No value specified for #{k}")[0]) if v == '' || v.nil? }
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          @engine, @root = get_engine(engine, options)

          # Exit if no data is provided or if no value is specified for a key
          data_check

          begin
            output = grab_results
            if output
              puts output
            else
              try = options[:edition] == 'enterprise' ? "'-e community' or remove the '-e' option" : "'-e enterprise'"
              no_results = "Search for '#{argv.join(', ')}': No results in edition #{options[:edition]}. Try #{try}"
              Simp::Metadata.critical(no_results)
            end
            @engine.save if @root
          rescue RuntimeError => e
            Simp::Metadata.critical(e.message)
            Simp::Metadata.backtrace(e.backtrace)
            exit 5
          end
        end
      end
    end
  end
end
