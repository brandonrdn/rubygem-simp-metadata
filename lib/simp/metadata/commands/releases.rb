module Simp
  module Metadata
    module Commands
      class Releases
        def run(argv, engine = nil)

          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata releases"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end.parse!(argv)
          end
          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
          end
          begin
            puts engine.releases.keys
          rescue RuntimeError => e
            Simp::Metadata.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end
