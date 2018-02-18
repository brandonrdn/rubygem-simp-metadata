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
            release = argv[0]
            section = argv[1]
            case section
              when "components"
                puts engine.releases[release].components.keys.join("\n")
              else
                puts "components:"
                engine.releases[release].components.keys.each do |line|
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
