module Simp
  module Metadata
    module Commands
      class Set_write
        def run(argv, engine = nil)
          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata set-write [options]"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end.parse!(argv)
          end
          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
            Simp::Metadata.warning("'set-write' subcommand is only useful in scripts!")
          end
          engine.writable_source = argv[0]
        end
      end
    end
  end
end
