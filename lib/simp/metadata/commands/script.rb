require 'optparse'

module Simp
  module Metadata
    module Commands
      class Script
        def run(argv, engine = nil)

          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata script [options] filename"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end.parse!(argv)
          end
          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
          end
          unless (argv[0] != nil)
            Simp::Metadata.critical("filename must be specified")
            exit 3
          end
          data = File.read(argv[0])
          lines = data.split("\n")
          lines.each do |line|
            temp_argv = line.split(" ")
            unless (temp_argv.size == 0)
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
