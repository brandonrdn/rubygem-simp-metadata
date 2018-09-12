require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Set_write_url < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          options = defaults(argv) do |opts,options|
            opts.banner = 'Usage: simp-metadata set-write-url <repo_name> <url>'
          end

          engine, root = get_engine(engine, options)
          engine.writable_url(argv[0], argv[1])
        end
      end
    end
  end
end
