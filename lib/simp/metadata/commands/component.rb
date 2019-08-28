require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Component Commands Class
      class Component < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root

        def description
          'Create, view, or update a component'
        end

        def valid_subcommands
          %w[view diff download build update create delete find_release]
        end

        def engine
          @engine
        end

        def root
          @root
        end

        def create
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata component create <component_name> setting=<value>'
            opts.banner << '    Creates a new component to be used within any Release'
          end
          @engine, @root = get_engine(engine, options)
          component = argv[2]
          argv.shift
          data = { 'locations' => [{ 'primary' => true }] }
          argv.each do |argument|
            split = argument.split('=')
            setting = split[0]
            value = split[1]
            case setting
            when 'authoritative'
              data[:authoritative] = value.to_s == 'true'
            when 'format'
              data[:format] = value
            when 'component-type'
              data[:component_type] = value
            when 'primary_url'
              data[:locations].first[:url] = value
            when 'primary_url_type'
              data[:locations].first[:type] = value
            end
          end
          engine.components.create(component, data)
        end

        def update
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata component update <component> <setting> <value>'
          end
          component = argv[1]
          setting = argv[2]
          value = argv[3]
          options[:component] = component
          @engine, @root = get_engine(engine, options)
          object = engine.releases[options[:release]].components[component]
          unless options[:release]
            Simp::Metadata.critical("A SIMP Release must be specified to edit components")
            exit 9
          end
          unless object.methods.include?(setting.to_sym)
            Simp::Metadata.critical("#{setting} is not a valid setting")
            exit 7
          end
          begin
            object.send("#{setting}=".to_sym, value)
          rescue NoMethodError => e
            Simp::Metadata.critical("#{setting} is a read-only setting")
            Simp::Metadata.critical(e.message)
            Simp::Metadata.backtrace(e.backtrace)
            exit 6
          end
        end

        def find_release
          options = defaults(argv) do |opts, _options|
            opts.banner = "Usage: simp-metadata component find_release <component> <attribute> <value>\n"
            opts.banner << "  Output latest release where specified value is set for component's attribute"
            opts.on('-s', '--show-all', 'Show all release matches') { |opt| options[:show_all] = opt }
          end
          @engine, @root = get_engine(engine, options)
          component = argv[1]
          attribute = argv[2]
          value = argv[3]

          releases = @engine.releases.keys
          releases.delete_if { |release| release =~ /test-/ }
          matches = []
          releases.each do |release|
            release_component = @engine.releases[release].components[component]
            matches.push(release) if release_component[attribute] == value
          end

          exit("No Releases found where #{component} #{attribute} = #{value}") if matches.empty?

          if options[:show_all]
            output = matches
          else
            matches.delete_if { |match| [/nightly-/,'unstable','development'].include?(match) }
            output = matches
          end
          puts output
        end

        def view
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata component view <component> [attribute]'
          end
          component = argv[1]
          attribute = argv[2]
          options[:component] = component
          @engine, @root = get_engine(engine, options)
          if @engine.components.key?(component)
            comp = if options[:release].nil?
                     @engine.components[component]
                   else
                     @engine.releases[options[:release]].components[component]
                   end
            view = comp.view(attribute)
            puts view.to_yaml
          else
            Simp::Metadata.critical("Unable to find component named #{component}")
            exit 5
          end
        end

        def diff
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata component diff <release1> <release2> <component> [attribute]'
          end
          @engine, @root = get_engine(engine, options)
          release1 = argv[1]
          release2 = argv[2]
          component = argv[3]
          attribute = argv[4]
          component1 = @engine.releases[release1].components[component]
          component2 = @engine.releases[release2].components[component]
          diff = component1.diff(component2, attribute)
          puts diff.to_yaml
        end

        def download
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata component download [-v <version>] <component>'
            options[:source] = []
            opts.on('-s', '--source [path/url]', 'URL or path to grab RPMs from (can be used multiple times') do |opt|
              options[:source] << opt
            end
            opts.on('-d', '--destination [path]', 'folder to build RPMs in') do |opt|
              options[:destination] = opt
            end
          end
          @engine, @root = get_engine(engine, options)
          component = argv[1]
          destination = options[:destination]
          source = options[:source] == [] ? nil : options[:source]
          if engine.components.key?(component)
            comp = if options[:release].nil?
                     engine.components[component]
                   else
                     engine.releases[options[:release]].components[component]
                   end
            comp.download(destination, source)
          else
            Simp::Metadata.critical('Unable to find component to download')
            exit 5
          end
        end

        def build
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata component build [-v <version>] <component>'
            opts.on('-d', '--destination [path]', 'folder to build RPMs in') do |opt|
              options[:destination] = opt
            end
          end
          @engine, @root = get_engine(engine, options)
          component = argv[1]
          destination = options[:destination]
          if engine.components.key?(component)
            release = options[:release] || 'unstable'
            comp = engine.releases[release].components[component]
            if comp.version == ''
              Simp::Metadata.critical("#{component} not found in SIMP #{release}")
              exit   11
            end
            comp.build(destination)
          else
            Simp::Metadata.critical('Unable to build component')
            exit 5
          end
        end

        def help
          defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata component [subcommand]'
            opts.banner << "  #{description}"
            opts.banner << "  subcommands:"
            valid_subcommands.each { |cmd| opts.banner << "    - #{cmd}" }
          end
        end

        def save
          engine.save(([:simp_metadata, 'component'] + argv).join(' ')) if @root
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          subcommand = %w[-h --help help].include?(argv[0]) ? 'help' : argv[0]
          public_send(subcommand)
          save
        rescue RuntimeError => e
          Simp::Metadata.critical(e.message)
          exit 5
        end
      end
    end
  end
end
