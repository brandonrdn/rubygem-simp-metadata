module Simp
  module Metadata
    module Commands
      class Base

        # Defines default arguments for commands
        def options(argv, &block)
          options = {}
          release = nil
          writable_url = nil
          ssh_key = nil
          edition = "community"
          options = OptionParser.new do |opts|

            opts.banner = "Usage: simp-metadata clone source_release target_release"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end
            opts.on("-v", "--version [release]", "release version") do |opt|
              release = opt
            end
            opts.on("-i", "--identity [ssh_key_file]", "specify ssh_key to be used") do |opt|
              ssh_key = opt
            end
            opts.on("-w", "--writable-url [component,url]", "writable component,url") do |opt|
              writable_url = opt
            end
            opts.on("-e", "--edition [edition]", "simp edition") do |opt|
              edition = opt
            end
            yield(opts)
          end
          options.parse!(argv)
          return options
        end
      end
    end
  end
end
