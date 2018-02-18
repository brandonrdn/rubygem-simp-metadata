require 'cgi'
require_relative '../commands'

module Simp
  module Metadata
    module Commands
      class Search < Simp::Metadata::Commands::Base

        def run(argv, engine = nil)

          options = defaults(argv) do |opts|
            opts.banner = "Usage: simp-metadata search <attribute>=<value>\n(supports multiple attributes as well as encoded URLs)"
          end


          engine, root = get_engine(engine, options)
          begin
            data = {}
            argv.each do |argument|
              splitted = argument.split("=")
              name = splitted[0]
              value = splitted[1]
              case name
                when name
                  data[name] = value
              end
            end
            unless (data == {}) or data.nil?
              data.each do |key, value|
                if value == "" or value.nil?
                  puts "No value specified for #{key}"
                  exit
                end
              end
              engine.components.each do |component|
                if data.all? {|key, value| component[key] == value or component[key] == CGI.unescape(value)}
                  puts component.name
                end
              end
            else
              puts "No search parameters specified"
            end
            if (root == true)
              engine.save
            end
          rescue RuntimeError => e
            Simp::Metadata.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end

