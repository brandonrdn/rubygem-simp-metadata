module Simp
  module Metadata
    module Commands
      class Release
        def run(argv, engine = nil)

          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata release [releasename] [components]"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end.parse!(argv)
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
