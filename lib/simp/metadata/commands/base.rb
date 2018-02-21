require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Base
        def get_engine(engine, options = {})
          root = false
          if (options["ssh_key"] != nil)
            options["ssh_key"] = File.expand_path(options["ssh_key"])
          end
          if (engine == nil)
            root = true
            metadatarepos = {}
            if (options["writable_urls"] != nil)
              array = options["writable_urls"].split(',')
              elements = array.size / 2;
              (0...elements).each do |offset|
                comp = array[offset * 2]
                url = array[(offset * 2) + 1]
                metadatarepos[comp] = url
              end
              engine = Simp::Metadata::Engine.new(nil, metadatarepos, options["edition"], options)
            else
              engine = Simp::Metadata::Engine.new(nil, nil, options["edition"], options)
            end
          else
            root = false
          end
          return engine, root
        end
        # Defines default arguments for commands
        def defaults(argv, &block)

          options = {
              "edition" => "community",
          }

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
            opts.on("-w", "--writable-urls [component,url]", "component,url") do |opt|
              options["writable_urls"] = opt
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
