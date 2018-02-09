module Simp
  module Metadata
    module Commands
      class Set_write < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options(argv) do
          end

          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
            Simp::Metadata.warning("'set-write' subcommand is only useful in scripts!")
          end
          engine.writable_source_name = argv[0]
        end
      end
    end
  end
end
