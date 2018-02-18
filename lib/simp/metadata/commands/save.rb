require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Save < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options = defaults(argv) do |opts|
            opts.banner = "Usage: simp-metadata save [options] [message]"
          end


          engine, root = get_engine(engine, options)
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
