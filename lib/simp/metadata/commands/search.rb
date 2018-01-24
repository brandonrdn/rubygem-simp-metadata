module Simp
  module Metadata
    module Commands
      class Search
        def run(argv, engine = nil)

          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata clone source_release target_release"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end.parse!(argv)
          end
          if (engine == nil)
            root = true
            engine = Simp::Metadata::Engine.new()
          else
            root = false
          end
          begin
            data = {}
            argv.each do |argument|
              splitted = argument.split("=")
              name = splitted[0]
              value = splitted[1]
              case name
                when "url"
                  data["url"] = value
              end
            end
            if (data != {})
              engine.components.each do |component|
                matches = component if component.primary.url == data["url"]
                if not matches.nil?
                puts matches
                end
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
