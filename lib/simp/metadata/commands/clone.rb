module Simp
  module Metadata
    module Commands
      class Clone
        def run(argv, engine = nil)

          writable_url = nil
          ssh_key = nil
          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata clone source_release target_release"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end
            opts.on("-i", "--identity [ssh_key_file]", "specify ssh_key to be used") do |opt|
              ssh_key = opt
            end
            opts.on("-w", "--writable-url [component,url]", "writable component,url") do |opt|
              writable_url = opt
            end
          end.parse!(argv)
          if (engine == nil)
            root = true
            engine = Simp::Metadata::Engine.new()
            if (writable_url != nil)
              comp, url = writable_url.split(',')
              engine.writable_url(comp, url)
            end
            if (ssh_key != nil)
              engine.ssh_key = File.expand_path(ssh_key)
            end
          else
            root = false
          end
          begin
            engine.releases.create(argv[1], argv[0])
            if (root == true)
              engine.save
            end
          rescue RuntimeError => e
            Simp::Metadata.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end
