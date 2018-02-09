module Simp
  module Metadata
    module Commands
      class Clone < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options(argv) do
          end

          if (ssh_key != nil)
            options["ssh_key"] = File.expand_path(ssh_key)
          end
          if (engine == nil)
            root = true
            metadatarepos = {}
            if (writable_urls != nil)
              array = writable_urls.split(',')
              elements = array.size / 2;
              (0...elements).each do |offset|
                comp = array[offset * 2]
                url = array[(offset * 2) + 1]
                metadatarepos[comp] = url
              end
              engine = Simp::Metadata::Engine.new(nil, metadatarepos, edition, options)
            end
          else
            root = false
          end
          begin
            engine.releases.create(argv[1], argv[0])
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
