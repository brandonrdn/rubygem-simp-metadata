require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Set the writable url for specified metadata name
      class SetWriteUrl < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root
        def description
          'Set writable URL for specified metadata name'
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata set-write-url <repo_name> <url>'
            opts.banner << "  #{description}"
          end

          @engine, @root = get_engine(engine, options)
          @engine.writable_url(argv[0], argv[1])
        end
      end
    end
  end
end
