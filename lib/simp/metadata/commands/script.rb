require 'optparse'
require_relative '../commands'

module Simp
  module Metadata
    module Commands
      class Script < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)

          options = defaults(argv) do |opts|
            opts.banner = "Usage: simp-metadata script [options] <filename>"
          end

          $commandqueue = Queue.new();

          engine, root = get_engine(engine, options)
          unless (argv[0] != nil)
            Simp::Metadata.critical("filename must be specified")
            exit 3
          end
          data = File.read(argv[0])
          lines = data.split("\n")
          lines.each do |line|
            temp_argv = line.split(" ")
            unless (temp_argv.size == 0)
              unless (temp_argv[0] =~ /^#/)
                $commandqueue.push(line);
                command = Module.const_get("Simp::Metadata::Commands::#{temp_argv[0].gsub("-","_").capitalize}").new()
                temp_argv.shift
                command.run(temp_argv, engine)
              end
            end
          end
        end
      end
    end
  end
end
