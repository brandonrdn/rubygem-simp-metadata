module Simp
  module Metadata
    module Commands
      class Save < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options(argv) do
          end

          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
            Simp::Metadata.warning("'save' subcommand is only useful in scripts!")
          end
          if (argv.size == 0)
            short = "Auto-saving using simp-metadata"
          else
            short = argv.join(" ")
          end
          if ($commandqueue != nil)
            message = []
            while $commandqueue.empty?() == false
              message << $commandqueue.pop
            end
            puts message
            engine.save("#{short}\n\nsimp-metadata log:\n    #{message.join("\n    ")}")
          else
            engine.save(short)
          end
        end
      end
    end
  end
end
