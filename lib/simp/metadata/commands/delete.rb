require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Delete < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options = defaults(argv) do | opts|
            opts.banner = "Usage: simp-metadata delete <component_name>"
          end

          engine, root = get_engine(engine, options)
          begin
            engine.releases.delete(argv[0])
            if (root == true)
              engine.save((["simp-metadata", "delete"] + argv).join(" "))
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
