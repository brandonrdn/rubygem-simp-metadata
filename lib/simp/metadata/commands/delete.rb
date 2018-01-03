module Simp
  module Metadata
    module Commands
      class Delete
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
            engine.releases.delete(argv[0])
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
