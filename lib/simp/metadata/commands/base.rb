require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Base
        def get_engine(engine, options = {})
          root = false
          unless options[:ssh_key].nil?
            options[:ssh_key] = File.expand_path(options[:ssh_key])
          end
          if engine.nil?
            root = true
            metadatarepos = {}
            if !options[:writable_urls].nil?
              array = options[:writable_urls].split(',')
              elements = array.size / 2
              (0...elements).each do |offset|
                comp = array[offset * 2]
                url = array[(offset * 2) + 1]
                metadatarepos[comp] = url
              end
              engine = Simp::Metadata::Engine.new(nil, metadatarepos, options[:edition], options)
            else
              engine = Simp::Metadata::Engine.new(nil, nil, options[:edition], options)
            end
          else
            root = false
          end
          [engine, root]
        end

        # Defines default arguments for commands
        def defaults(argv)
          options = {
              :edition => ENV.fetch('SIMP_METADATA_EDITION', 'community')
          }
          if ENV.fetch('SIMP_METADATA_WRITABLE_URLS', nil) != nil
            options[:writable_urls] = ENV['SIMP_METADATA_WRITABLE_URLS']
          end
          option_parser = OptionParser.new do |opts|
            opts.banner = 'Usage: simp-metadata <command> [options]'
            opts.on('-d', '--debug [level]', 'debug logging level: critical, error, warning, info, debug1, debug2') do |debug|
              $simp_metadata_debug_level = debug
            end
            opts.on('-v', '--version [release]', 'release version') do |release|
              options[:release] = release
            end
            opts.on('-i', '--identity [ssh_key_file]', 'specify ssh_key to be used') do |identity|
              options[:ssh_key] = identity
            end
            opts.on('-w', '--writable-urls [component,url]', 'component,url') do |writable_urls|
              options[:writable_urls] = writable_urls
            end
            opts.on('-e', '--edition [edition]', 'simp edition') do |edition|
              options[:edition] = edition
            end
            opts.on('-p', '--platform [platform]', 'el_version to use', 'valid platforms:', ' - el6', ' - el7') do |platform|
              options[:platform] = platform
            end
            yield(opts,options) if block_given?
          end
          option_parser.parse!(argv)
          options
        end
      end
    end
  end
end
