require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Delete SIMP Release from metadata
      class Delete < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root
        def description
          'Deletes a release'
        end

        def delete
          @engine.releases.delete(@argv[0])
        end

        def save
          @engine.save(([:simp_metadata, 'delete'] + argv).join(' ')) if @root
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata delete <release>'
            opts.banner << "  #{description}"
          end

          @engine, @root = get_engine(engine, options)
          begin
            delete
            save
          rescue RuntimeError => e
            Simp::Metadata.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end
