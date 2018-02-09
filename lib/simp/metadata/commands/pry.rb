module Simp
  module Metadata
    module Commands
      class Pry < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options(argv) do
          end

          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
            Simp::Metadata.warning("'pry' subcommand is only useful in scripts!")
          end
          require 'pry'
          binding.pry
        end
      end
    end
  end
end
