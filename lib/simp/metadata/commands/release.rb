require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Release < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options = defaults(argv) do |opts|
            opts.banner = "Usage: simp-metadata release <release_name> <components>"
          end


          engine, root = get_engine(engine, options)
          begin
            section = argv[0]
            case section
              when "components"
                puts engine.releases[options["release"]].components.keys.join("\n")
              when "puppetfile"
                type = argv[1]
                puts engine.releases[options["release"]].puppetfile({ "type" => type})
              else
                puts "components:"
                engine.releases[options["release"]].components.keys.each do |line|
                  puts "    #{line}"
                end
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
