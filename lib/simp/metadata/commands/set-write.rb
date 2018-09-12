require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Set_write < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          options = defaults(argv) do |opts,options|
            opts.banner = 'Usage: simp-metadata set-write [options]'
          end

          engine, root = get_engine(engine, options)
          engine.writable_source_name = argv[0]
        end
      end
    end
  end
end
