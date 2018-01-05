module Simp
  module Metadata
    module Commands
      class Update
        def run(argv, engine = nil)
          release = nil
          OptionParser.new do |opts|

            opts.banner = "Usage: simp-metadata clone source_release target_release"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end
            opts.on("-v", "--version [release]", "release version") do |opt|
              release = opt
            end
          end.parse!(argv)

          if (engine == nil)
            root = true
            engine = Simp::Metadata::Engine.new()
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
