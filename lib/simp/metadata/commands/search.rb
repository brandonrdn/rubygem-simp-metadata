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
            opts.banner = "Usage: simp-metadata search [<attribute>=<value> || <keyword>]"
            opts.banner << "  #{description}"
            opts.banner << "  - supports multiple attributes"
            opts.banner << "  - supports encoded URLs"
            opts.banner << "  - can find components based on a keyword (i.e. part of the module name)"
          end
        end

        def data(input = @argv)
          data = {}
          input.each do |argument|
            split_by = [' ', ',']
            split = argument.split(Regexp.union(split_by))
            split.each do |search|
              if search =~ /=/
                data[search.split('=')[0]] = search.split('=')[1]
              else
                (data[:keywords] ||= []) << search
              end
            end
          end
          data
        end

        def grab_results(input = @argv)
          results = {}
          data = data(input)
          @engine.components.each do |component|
            attribute_search_hash = data.reject { |k, _v| [:keywords].include? k }
            result = nil
            unless attribute_search_hash.empty?
              result = attribute_search_hash.all? do |attribute, value|
                if attribute == 'url'
                  component.locations.any? do |location|
                    location.url == value || location.url == CGI.unescape(value)
                  end
                else
                  component[attribute] == value || component[attribute] == CGI.unescape(value)
                end
              end
            end
            if result
              results[component.to_s] = true
            elsif data[:keywords]
              comp_data = component.data_array
              results[component.to_s] = true if data[:keywords].all? { |s| comp_data.any?{ |key| "#{s}" == key } }
            end
          end
          # Grab exact results
          if results.empty?
            @engine.components.each do |component|
              comp_data = component.data_array
              results[component.to_s] = true if data[:keywords].all? { |s| comp_data.any?{ |key| /#{s}/ =~ key } }
            end
          end
          # Grab regex matches if no exact matches are found
          results.keys.empty? ? nil : results.keys
        end

        def data_backup
          data = {}
          @argv.each do |argument|
            split = argument.split('=')
            name = split[0]
            value = split[1]
            data[name] = value
          end
          data
        end

        def grab_results_backup
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
          exit(Simp::Metadata::Debug.warning('No search parameters specified')[0]) if (data == {}) || data.nil?
          data.each { |k, v| exit(Simp::Metadata::Debug.info("No value specified for #{k}")[0]) if v == '' || v.nil? }
        end

        def search(input, options = {})
          @argv = input
          @engine, @root = get_engine(nil, options)
          grab_results
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
              Simp::Metadata::Debug.critical(no_results)
            end
            # @engine.save if @root
          rescue RuntimeError => e
            Simp::Metadata::Debug.critical(e.message)
            Simp::Metadata::Debug.backtrace(e.backtrace)
            exit 5
          end
        end
      end
    end
  end
end
