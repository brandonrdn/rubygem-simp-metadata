require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Base
        def get_engine(engine, options)
          if (options["ssh_key"] != nil)
            options["ssh_key"] = File.expand_path(options["ssh_key"])
          end
          if (engine == nil)
            root = true
            engine = Simp::Metadata::Engine.new(nil, nil, "community", options)
            if (options["writable_url"] != nil)
              comp, url = options["writable_url"].split(',')
              engine.writable_url(comp, url)
            end
          else
            root = false
          end
          return engine, root
        end
        # Defines default arguments for commands
        def defaults(argv, &block)

          options = {}

          option_parser = OptionParser.new do |opts|

            opts.banner = "Usage: simp-metadata <command> [options]"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end
            opts.on("-v", "--version [release]", "release version") do |opt|
              options["release"] = opt
            end
            opts.on("-i", "--identity [ssh_key_file]", "specify ssh_key to be used") do |opt|
              options["ssh_key"] = opt
            end
            opts.on("-w", "--writable-url [component,url]", "component,url") do |opt|
              options["writable_url"] = opt
            end
            opts.on("-e", "--edition [edition]", "simp edition") do |opt|
              options["edition"] = opt
            end
            yield(opts) if block_given?
          end
          option_parser.parse!(argv)
          return options
        end
      end
    end
  end
end
