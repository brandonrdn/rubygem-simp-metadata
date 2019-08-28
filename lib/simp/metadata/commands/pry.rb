require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Pry Class for debugging
      class Pry < Simp::Metadata::Commands::Base
        def description
          'Opens up pry debugger'
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata pry'
            opts.banner << "  #{description}"
          end

          @engine, @root = get_engine(engine, options)
          require 'pry'
        end
      end
    end
  end
end
