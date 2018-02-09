module Simp
  module Metadata
    module Commands
      class Set_write_url
        def run(argv, engine = nil)

          options(argv) do
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
