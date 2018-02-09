module Simp
  module Metadata
    module Commands
      class Releases
        def run(argv, engine = nil)

          options(argv) do
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
