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
          %w[view diff download build update create delete find]
        end

        def create
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata component create <component_name> <setting>=<value>'
            opts.banner << 'Info: Creates a new component to be used within any Release'
            opts.banner << 'Required: primary_url must be passed as a setting'
            opts.banner << 'Defaults:'
            opts.banner << '    - authoritative: true'
            opts.banner << '    - component-type: puppet-module'
            opts.banner << '    - package-name: nil (Specify package(rpm) name if it differs from component name)'
            opts.banner << '    - format: git'
            opts.banner << '    - primary location type: git'
          end
          @engine, @root = get_engine(engine, options)
          argv.shift
          component = argv[0]
          argv.shift
          data = { 'authoritative' => true, 'format' => 'git', 'component-type' => 'puppet-module',
                   'locations' => [{ 'url' => nil, 'type' => 'git','primary' => true }] }
          argv.each do |argument|
            split = argument.split('=')
            setting = split[0].gsub('_','-')
            value = if split[1] == 'false'
                      false
                    elsif split[1] == 'true'
                      true
                    else
                      split[1].to_s
                    end
            case setting
            when 'authoritative', 'format', 'component-type', 'package-name'
              data[setting.to_s] = value
            when 'primary-url'
              data['locations'].first['url'] = value
            when 'primary-url-type'
              data['locations'].first['type'] = value
            else
              Simp::Metadata::Debug.debug_level('debug2')
              valid_settings = ['Valid Settings:','  -authoritative',  '  -package-name', '  -format',
                                '  -component-type', '  -primary-url', '  -primary-url-type']
              Simp::Metadata::Debug.info(valid_settings)
              Simp::Metadata::Debug.info("Release specific information (ref, tag, etc) can not be used.")
              Simp::Metadata::Debug.abort("Unrecognized setting #{setting} for component creation.")
            end
          end
          Simp::Metadata::Debug.abort("Must pass primary_url to create component") unless data['locations'].first['url']
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
          # ToDo: Update code to allow non-release settings to be updated
          unless options[:release]
            Simp::Metadata::Debug.abort("A SIMP Release (-r RELEASE) must be specified to edit components.")
          end
          unless engine.base_components.key?(component)
            Simp::Metadata::Debug.abort("Component does not exist in metadata. Try `simp-metadata component add`.")
          end

          unless engine.releases[options[:release]].components.key?(component)
            Simp::Metadata::Debug.abort("Component #{component} does not exit in release #{options[:release]}")
          end

          object = engine.releases[options[:release]].components[component]
          methods = object.methods
          Simp::Metadata::Debug.abort("#{setting} is not a valid setting") unless methods.include?(setting.to_sym)
          begin
            object.send("#{setting}=".to_sym, value)
          rescue NoMethodError => e
            Simp::Metadata::Debug.critical(e.message)
            Simp::Metadata::Debug.backtrace(e.backtrace)
            Simp::Metadata::Debug.abort("#{setting} is a read-only setting")
          end
        end

        def find
          options = defaults(argv) do |parser, options|
            parser.banner = "Usage: simp-metadata component find <component> <attribute> <value>\n"
            parser.banner << "  Output latest release where specified value is set for component's attribute"
            parser.on('-s', '--show-all', 'Show all release matches') do |show_all|
              options[:show_all] = show_all
            end
          end
          @engine, @root = get_engine(engine, options)
          component = argv[1]
          attribute = argv[2]
          value = argv[3]

          releases = @engine.releases.keys
          releases.delete_if { |release| release =~ /test-/ }
          matches = []
          releases.each do |release|
            next unless @engine.releases[release].components.key?(component)

            release_component = @engine.releases[release].components[component]
            matches.push(release) if release_component[attribute] == value
          end

          exit("No Releases found where #{component} #{attribute} = #{value}") if matches.empty?
          regex_array = [/nightly/, /unstable/, /dev/]
          if options[:show_all]
            puts matches
          else
            matches.delete_if { |match| match.match?(Regexp.union(regex_array)) } unless options[:show_all]
            *_rest, last = matches.sort
            puts last
          end
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
            if @engine.base_components.key?(component)
              Simp::Metadata::Debug.abort("Component #{component} is not utilized in release #{options[:release]}")
            else
              Simp::Metadata::Debug.abort("Unable to find component named #{component}")
            end
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
            Simp::Metadata::Debug.critical('Unable to find component to download')
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
              Simp::Metadata::Debug.critical("#{component} not found in SIMP #{release}")
              exit 11
            end
            comp.build(destination)
          else
            Simp::Metadata::Debug.critical('Unable to build component')
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

        def grab_component(input, options = {})
          # ToDo: Make the search use engines if they already exist. Current method repeats engine grabs
          # ToDo: w/ and w/o proper options set, causing bad data and extra time/resources to be spent
          search = Simp::Metadata::Commands::Search.new
          result = search.search([input], options)
          if result.size == 1
            result[0]
          else
            Simp::Metadata::Debug.debug_level('debug2')
            warning = 'Multiple components found based on input. Please specify a component from the group above'
            pretty_print_matches = ["Components matching input:"]
            result.each {|res| pretty_print_matches.push("  -#{res}")}
            Simp::Metadata::Debug.info(pretty_print_matches)
            Simp::Metadata::Debug.abort(warning)
          end
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          subcommand = %w[-h --help help].include?(argv[0]) ? 'help' : argv[0]
          public_send(subcommand)
          save
        rescue RuntimeError => e
          Simp::Metadata::Debug.critical(e.message)
          exit 5
        end
      end
    end
  end
end
