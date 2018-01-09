module Simp
  module Metadata
    module Commands
      class Pry
        def run(argv, engine = nil)
          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata save [options]"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end.parse!(argv)
          end
          if (engine == nil)
            engine = Simp::Metadata::Engine.new()
            Simp::Metadata.warning("'pry' subcommand is only useful in scripts!")
          end
          require 'pry'
          binding.pry
        end
      end
    end
  end
end
