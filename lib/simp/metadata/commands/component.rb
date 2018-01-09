module Simp
  module Metadata
    module Commands
      class Component
        def run(argv, engine = nil)
          release = nil
          OptionParser.new do |opts|

            opts.banner = "Usage: simp-metadata component create component_name name=value"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end
          end.parse!(argv)

          if (engine == nil)
            root = true
            engine = Simp::Metadata::Engine.new()
          else
            root = false
          end
          begin
            subcommand = argv[0]
            case subcommand
              when "create"
                component = argv[1]
                argv.shift
                data = { "locations" => [{ "primary" => true}]}
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
