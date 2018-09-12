require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Save < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          options = defaults(argv) do |opts,options|
            opts.banner = 'Usage: simp-metadata save [options] [message]'
          end

          engine, root = get_engine(engine, options)
          short = if argv.empty?
                    'Auto-saving using simp-metadata'
                  else
                    argv.join(' ')
                  end

          if $commandqueue.nil?
            engine.save(short)
          else
            message = []
            message << $commandqueue.pop until $commandqueue.empty?
            puts message
            engine.save("#{short}\n\nsimp-metadata log:\n    #{message.join("\n    ")}")
          end
        end
      end
    end
  end
end
