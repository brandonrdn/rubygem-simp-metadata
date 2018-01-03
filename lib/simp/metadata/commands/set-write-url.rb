module Simp
  module Metadata
    module Commands
      class Set_write_url
        def run(argv, engine = nil)
          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata set-write-url reponame url"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end.parse!(argv)
          end
          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
            Simp::Metadata.warning("'set-write-url' subcommand is only useful in scripts!")
          end

          engine.writable_url(argv[0], argv[1])
        end
      end
    end
  end
end
