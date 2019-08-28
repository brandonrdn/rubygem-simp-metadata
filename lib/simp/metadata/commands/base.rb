require_relative '../commands'
require_relative '../version'

module Simp
  module Metadata
    module Commands
      # Base methods for all commands
      class Base
        def get_engine(engine, options = {})
          options[:ssh_key] = File.expand_path(options[:ssh_key]) unless options[:ssh_key].nil?
          options[:el_version] = 'el7' unless options[:el_version]
          if engine.nil?
            root = true
            metadata_repos = {}
            if options[:writable_urls]
              array = options[:writable_urls].split(',')
              joined = array.each_slice(2).to_a
              joined.each { |name, url| metadata_repos[name] = url }
            end
              engine = Simp::Metadata::Engine.new(nil, metadata_repos, options)
          else
            root = false
          end
          [engine, root]
        end

        # Allow --version or -v to output version without messing with options
        if %w[--version -v].include?(ARGV[0])
          puts Simp::Metadata::Version.version
          exit 0
        end

        def debug_levels
          %w[critical error warning info debug1 debug2]
        end

        # Defines default arguments for commands
        def defaults(argv)
          options = {
            edition: ENV.fetch('SIMP_METADATA_EDITION', 'community')
          }
          unless ENV.fetch('SIMP_METADATA_WRITABLE_URLS', nil).nil?
            options[:writable_urls] = ENV['SIMP_METADATA_WRITABLE_URLS']
          end
          option_parser = OptionParser.new do |parser|
            parser.banner = 'Usage: simp-metadata <command> [options]'
            parser.on('-d', '--debug [LEVEL]', "debug logging level: #{debug_levels.join(' ')}") do |opt|
              Simp::Metadata.debug_level(opt)
            end
            parser.on('-r', '--release [RELEASE]', 'SIMP release version') { |opt| options[:release] = opt }
            parser.on('-i', '--identity [ssh_key_file]', 'specify ssh_key to use') { |opt| options[:ssh_key] = opt }
            parser.on('-w', '--writable-urls [COMPONENT,URL]', 'component,url') { |opt| options[:writable_urls] = opt }
            parser.on('-n', '--skip_cache_update', "Skip data cache update") { |opt| options[:skip_cache_update] = opt }
            parser.on('-e', '--edition [edition]', 'SIMP edition (community or enterprise). Default: community') do |opt|
              options[:edition] = opt
            end
            parser.on('-E', '--el_version [el_version]', 'el_version(el6 or el7) to use (Default: el7)') do |opt|
              options[:os_version] = opt
            end
            parser.on('-m', '--metadata_version [version]', 'metadata version(v1 or v2) to use (Default: v2)') do |opt|
              options[:metadata_version] = opt
            end
            yield(parser, options) if block_given?
          end
          option_parser.parse!(argv)
          options
        end
      end
    end
  end
end
