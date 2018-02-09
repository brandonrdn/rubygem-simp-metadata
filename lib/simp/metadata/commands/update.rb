module Simp
  module Metadata
    module Commands
      class Update
        def run(argv, engine = nil)

          options(argv) do
          end

          if (ssh_key != nil)
            options["ssh_key"] = File.expand_path(ssh_key)
          end
          if (engine == nil)
            root = true
            engine = Simp::Metadata::Engine.new(nil, nil, "community", options)
            if (writable_url != nil)
              comp, url = writable_url.split(',')
              engine.writable_url(comp, url)
            end
          else
            root = false
          end
          begin
            component = argv[0]
            setting = argv[1]
            value = argv[2]
            if (release == nil)
              object = engine.components[component]
            else
              object = engine.releases[release].components[component]
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
