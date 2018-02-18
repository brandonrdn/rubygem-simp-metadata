require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Update < Simp::Metadata::Commands::Base

        def run(argv, engine = nil)

          options = defaults(argv) do |opts|
            opts.banner = "Usage: simp-metadata update <component> <setting> <value>"
          end


          engine, root = get_engine(engine, options)
          begin
            component = argv[0]
            setting = argv[1]
            value = argv[2]
            if (options["release"] == nil)
              object = engine.components[component]
            else
              object = engine.releases[options["release"]].components[component]
            end
            unless (object.methods.include?(setting.to_sym))
              Simp::Metadata.critical("#{setting} is not a valid setting")
              exit 7
            end

            begin
              object.send("#{setting}=".to_sym, value)
            rescue NoMethodError => ex
              Simp::Metadata.critical("#{setting} is a read-only setting")
              exit 6
            end

            if (root == true)
              engine.save
            end
          rescue RuntimeError => e
            Simp::Metadata.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end
