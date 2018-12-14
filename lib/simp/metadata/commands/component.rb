require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Component < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          subcommand = argv[0]

          case subcommand
          when '--help', '-h'
            options = defaults(argv) do |opts,options|
              opts.banner = 'Usage: simp-metadata component [ view | diff | download | build | update | create ]'
            end

          when 'create'
            options = defaults(argv) do |opts,options|
              opts.banner = 'Usage: simp-metadata component create <component_name> name=<value>'
            end
            engine, root = get_engine(engine, options)
            component = argv[1]
            argv.shift
            data = {'locations' => [{'primary' => true}]}
            argv.each do |argument|
              splitted = argument.split('=')
              name = splitted[0]
              value = splitted[1]
              case name
              when 'authoritative'
                data['authoritative'] = value.to_s == 'true'
              when 'format'
                data['format'] = value
              when 'component-type'
                data['component-type'] = value
              when 'primary_url'
                data['locations'].first['url'] = value
              when 'primary_url_type'
                data['locations'].first['type'] = value
              end
            end
            engine.components.create(component, data)

          when 'update'
            options = defaults(argv) do |opts,options|
              opts.banner = 'Usage: simp-metadata component update <component> <setting> <value>'
            end
            engine, root = get_engine(engine, options)
            component = argv[1]
            setting = argv[2]
            value = argv[3]
            object = engine.components[component]
            unless object.methods.include?(setting.to_sym)
              Simp::Metadata.critical("#{setting} is not a valid setting")
              exit 7
            end
            begin
              object.send("#{setting}=".to_sym, value)
            rescue NoMethodError => ex
              Simp::Metadata.critical("#{setting} is a read-only setting")
              exit 6
            end

          when 'find_release'
            options = defaults(argv) do |opts, options|
              opts.banner = "Usage: simp-metadata component find_release <component> <attribute> <value>\n"
              opts.banner << "  Output releases where specified components <attribute> matches <value>"
              opts.on('-s', '--show-all', 'Shows all release matches, including unstable and nightlies') do |show_all|
                options['show_all'] = show_all
              end
            end
            engine, root = get_engine(engine, options)
            component = argv[1]
            attribute = argv[2]
            value = argv[3]

            releases = engine.releases.keys - ['test-stub','test-diff','test-nightly-2018-02-08','5.1.0-2','5.1.0-1','5.1.0-0','4.2.0-0','5.1.0-RC1','5.1.0-Beta','4.2.0-RC1','4.2.0-Beta2']
            matches = releases.select{ |release| puts "true" if engine.releases[release].components[component].version?; engine.releases[release].components[component][attribute] == value}
            if options['show_all']
              output = matches
            else
              delete = ['unstable']
              matches.each{ |match| delete.push(match) if match =~ /nightly-/ }
              output = matches - delete
            end
            puts output

          when 'view'
            options = defaults(argv) do |opts,options|
              opts.banner = 'Usage: simp-metadata component view <component> [attribute]'
            end
            engine, root = get_engine(engine, options)
            component = argv[1]
            attribute = argv[2]
            if engine.components.key?(component)
              if options['release'].nil?
                comp = engine.components[component]
              else
                comp = engine.releases[options['release']].components[component]
              end
              view = comp.view(attribute)
              puts view.to_yaml
            else
              Simp::Metadata.critical("Unable to find component named #{component}")
              exit 5
            end

          when 'diff'
            options = defaults(argv) do |opts,options|
              opts.banner = 'Usage: simp-metadata component diff <release1> <release2> <component> [attribute]'
            end
            engine, root = get_engine(engine, options)
            release1 = argv[1]
            release2 = argv[2]
            component = argv[3]
            attribute = argv[4]
            component1 = engine.releases[release1].components[component]
            component2 = engine.releases[release2].components[component]
            diff = component1.diff(component2, attribute)
            puts diff.to_yaml

          when 'download'
            options = defaults(argv) do |opts,options|
              opts.banner = 'Usage: simp-metadata component download [-v <version>] [-d <destination>] [-s <source>] <component>'
              options['source'] = []
              opts.on('-s', '--source [path/url]', 'URL or path to grab RPMs from (can be passed more than once)') do |opt|
                options['source'] << opt
              end
              opts.on('-d', '--destination [path]', 'folder to build RPMs in') do |opt|
                options['destination'] = opt
              end
            end
            engine, root = get_engine(engine, options)
            component = argv[1]
            destination = options['destination']
            source = options['source']
            if engine.components.key?(component)
              if options['release'].nil?
                comp = engine.components[component]
              else
                comp = engine.releases[options['release']].components[component]
              end
              comp.download(destination, source)
            else
              Simp::Metadata.critical('Unable to find component to download')
              exit 5
            end

          when 'build'
            options = defaults(argv) do |opts,options|
              opts.banner = 'Usage: simp-metadata component build [-v <version>] [-d <destination>] [-s <source>] <component>'
              opts.on('-d', '--destination [path]', 'folder to build RPMs in') do |opt|
                options['destination'] = opt
              end
            end
            engine, root = get_engine(engine, options)
            component = argv[1]
            destination = options['destination']
            if engine.components.key?(component)
              if options['release'].nil?
                comp = engine.components[component]
              else
                comp = engine.releases[options['release']].components[component]
              end
              comp.build(destination)
            else
              Simp::Metadata.critical('Unable to build component')
              exit 5
            end

          else
            abort(Simp::Metadata.critical("Unrecognized subcommand '#{subcommand}}'.")[0])
          end

          engine.save((['simp-metadata', 'component'] + argv).join(' ')) if root
        rescue RuntimeError => e
          Simp::Metadata.critical(e.message)
          exit 5
        end
      end
    end
  end
end
