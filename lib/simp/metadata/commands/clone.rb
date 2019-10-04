require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Command to clone SIMP Releases
      class Clone < Simp::Metadata::Commands::Base
        attr_accessor :root, :engine, :argv
        def description
          'Clone one SIMP release into another'
        end

        def run(argv, engine = nil)
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata clone <source_release> <target_release>'
            opts.banner << "  #{description}"
          end

          @engine, @root = get_engine(engine, options)

          begin
            @engine.releases.create(argv[1], argv[0])
            @engine.save(([:simp_metadata, 'clone'] + argv).join(' ')) if @root
          rescue RuntimeError => e
            Simp::Metadata::Debug.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end
