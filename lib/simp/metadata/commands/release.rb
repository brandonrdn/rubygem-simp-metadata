module Simp
  module Metadata
    module Commands
      class Release
        def run(argv, engine = nil)

          options(argv) do
          end

          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
          end
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
