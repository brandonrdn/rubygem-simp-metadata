require 'cgi'
require_relative '../commands'

module Simp
  module Metadata
    module Commands
      class Search < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          options = defaults(argv) do |opts,options|
            opts.banner = "Usage: simp-metadata search <attribute>=<value>\n(supports multiple attributes as well as encoded URLs)"
          end

          engine, root = get_engine(engine, options)
          begin
            data = {}
            argv.each do |argument|
              splitted = argument.split('=')
              name = splitted[0]
              value = splitted[1]
              case name
              when name
                data[name] = value
              end
            end

            if (data == {}) || data.nil?
              puts 'No search parameters specified'
            else
              data.each do |key, value|
                if value == '' || value.nil?
                  puts "No value specified for #{key}"
                  exit
                end
              end

              engine.components.each do |component|
                result = data.all? do |key, value|
                  if key == 'url'
                    component.locations.any? do |location|
                      location.url == value || location.url == CGI.unescape(value)
                    end
                  else
                    component[key] == value || component[key] == CGI.unescape(value)
                  end
                end

                puts component.name if result
              end
            end

            engine.save if root
          rescue RuntimeError => e
            Simp::Metadata.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end
