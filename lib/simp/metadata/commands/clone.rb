require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Clone < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options = defaults(argv) do |opts|
            opts.banner = "Usage: simp-metadata clone <source_release> <target_release>"
          end
          engine, root = get_engine(engine, options)

          begin
            engine.releases.create(argv[1], argv[0])
            if (root == true)
              engine.save((["simp-metadata", "clone"] + argv).join(" "))
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
