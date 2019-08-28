require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Set which repo to write to
      class SetWrite < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root

        def description
          'Sets which metadata repo to write to if there are multiple'
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          options = defaults(@argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata set-write [options]'
            opts.banner << "  #{description}"
          end

          @engine, @root = get_engine(engine, options)
          @engine.writable_source_name = argv[0]
        end
      end
    end
  end
end
