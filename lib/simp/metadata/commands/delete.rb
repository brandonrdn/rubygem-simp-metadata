module Simp
  module Metadata
    module Commands
      class Delete
        def run(argv, engine = nil)

          writable_urls = nil
          ssh_key = nil
          edition = "community"
          OptionParser.new do |opts|
            opts.banner = "Usage: simp-metadata clone source_release target_release"
            opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
              $simp_metadata_debug_level = opt
            end

            opts.on("-i", "--identity [ssh_key_file]", "specify ssh_key to be used") do |opt|
              ssh_key = opt
            end
            opts.on("-w", "--writable-url [component,url[,component,url]]", "writable component,url") do |opt|
              writable_urls = opt
            end
            opts.on("-e", "--edition [edition]", "simp edition") do |opt|
              edition = opt
            end
          end.parse!(argv)

          if (engine == nil)
            root = true
            metadatarepos = {}
            if (writable_urls != nil)
              array = writable_urls.split(',')
              elements = array.size / 2;
              (0...elements).each do |offset|
                comp = array[offset * 2]
                url = array[(offset * 2) + 1]
                metadatarepos[comp] = url
              end
              engine = Simp::Metadata::Engine.new(nil, metadatarepos, edition)
            end
            if (ssh_key != nil)
              engine.ssh_key = File.expand_path(ssh_key)
            end
          else
            root = false
          end
          begin
            engine.releases.delete(argv[0])
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
