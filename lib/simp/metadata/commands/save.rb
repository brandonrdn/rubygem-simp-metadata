require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # metadata save Class
      class Save < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root
        @command_queue = nil

        def description
          'Save metadata changes'
        end

        def command_queue(setting = nil)
          if @command_queue.nil?
            @command_queue = setting
          else
            @command_queue.push(setting)
          end
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata save [options] [message]'
            opts.banner << "  #{description}"
          end

          @engine, @root = get_engine(engine, options)
          short = @argv.empty? ? 'Auto-saving using simp-metadata' : argv.join(' ')

          if @command_queue.nil?
            engine.save(short)
          else
            message = []
            message << @command_queue.pop until @command_queue.empty?
            puts message
            engine.save("#{short}\n\nsimp-metadata log:\n    #{message.join("\n    ")}")
          end
        end
      end
    end
  end
end
