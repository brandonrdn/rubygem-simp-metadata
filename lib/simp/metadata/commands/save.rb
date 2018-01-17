module Simp
  module Metadata
    module Commands
      class Save
        def run(argv, engine = nil)
          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata save [options] [message]"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end.parse!(argv)
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
