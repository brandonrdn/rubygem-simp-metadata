require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Pry < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          options = defaults(argv) do |opts|
            opts.banner = 'Usage: simp-metadata pry'
          end

          engine, root = get_engine(engine, options)
          require 'pry'
        end
      end
    end
  end
end
