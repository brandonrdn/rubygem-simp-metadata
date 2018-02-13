require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Component < Simp::Metadata::Commands::Base

        def run(argv, engine = nil)

          if (engine == nil)
            root = true
            engine = Simp::Metadata::Engine.new()
          else
            root = false
          end
          begin
            subcommand = argv[0]
            case subcommand
              when "--help", "-h"
                options = defaults(argv) do |opts|
                  opts.banner = "Usage: simp-metadata component [ create | view | update ]"
                end
              when "create"
                options = defaults(argv) do |opts|
                  opts.banner = "Usage: simp-metadata component create <component_name> name=<value>"
                end
                component = argv[1]
                argv.shift
                data = {"locations" => [{"primary" => true}]}
                argv.each do |argument|
                  splitted = argument.split("=")
                  name = splitted[0]
                  value = splitted[1]
                  case name
                    when "authoritative"
                      data["authoritiative"] = value.to_s == "true"
                    when "format"
                      data["format"] = value
                    when "component-type"
                      data["component-type"] = value
                    when "primary_url"
                      data["locations"].first["url"] = value
                    when "primary_url_type"
                      data["locations"].first["type"] = value
                  end
                end
                engine.components.create(component, data)
              when "update"
                options = defaults(argv) do |opts|
                  opts.banner = "Usage: simp-metadata component update <component> <setting> <value>"
                end
                component = argv[1]
                setting = argv[2]
                value = argv[3]
                object = engine.components[component]
                unless (object.methods.include?(setting.to_sym))
                  Simp::Metadata.critical("#{setting} is not a valid setting")
                  exit 7
                end
                begin
                  object.send("#{setting}=".to_sym, value)
                rescue NoMethodError => ex
                  Simp::Metadata.critical("#{setting} is a read-only setting")
                  exit 6
                end
              when "view"
                options = defaults(argv) do |opts|
                  opts.banner = "Usage: simp-metadata component view <component> [attribute]"
                end
                component = argv[1]
                attribute = argv[2]
                comp = engine.components[component]
                if attribute.nil?
                  comp.each do |key, value|
                    unless value.nil? or value == ""
                      puts "#{key}: #{value}"
                    end
                  end
                  puts "location:"
                  comp.locations.each do |location|
                    location.each do |key, value|
                      unless value.nil?
                        puts "  #{key}: #{value}"
                      end
                    end
                  end
                else
                  puts comp[attribute]
                end
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
