require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Releases Class to show all Releases for SIMP
      class Releases < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root

        def description
          'List all SIMP releases'
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata releases'
            opts.banner << "  #{description}"
          end

          @engine, @root = get_engine(engine, options)
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
