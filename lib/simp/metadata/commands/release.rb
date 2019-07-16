require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Release < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          subcommand = argv[0]

          case subcommand

          when '--help', '-h'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release [ components | diff | add_component | delete_component | platforms | puppet_versions | isos | puppetfile ]'
            end

          when 'components'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release <release_name> components'
              opts.banner += "\n-Creates a clean list of only the component names for the specified release."
            end
            engine, root = get_engine(engine, options)
            puts engine.releases[options['release']].components.keys.join("\n")

          when 'component'
            sub_subcommand = argv[1]
            case sub_subcommand
            when 'add'
              puts "HERE"

              options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release component add <-v release> <component_name> setting=value(can be multiple'
              opts.banner << '    Adds a SIMP component for a specific release'
              opts.banner << '      - Must include at least one setting (ref, tag, or branch)'
            end
            engine, root = get_engine(engine, options)
            release = options['release']
            _command, _subcommand, component, *input = argv
            hash = {}
            input.each do |settings|
              setting = settings.split('=')[0]
              value = settings.split('=')[-1]
              hash[setting] = value
            end
            new_data = {}
            ['ref','tag','branch'].each {|key| new_data[key] = hash[key] if hash[key]}
            abort(Simp::Metadata.critical("Must include at least one setting in a hash. i.e. {'tag' => '1.2.3'}")[0]) unless argv[2]
            abort(Simp::Metadata.critical("Must specify Release from which to remove component")[0]) unless options['release']
            engine.releases[release].add_component(component, new_data)

          when 'delete'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release component delete <-v release> <component_name>'
              opts.banner << '    Removes a SIMP component from a specific release'
            end
            engine, root = get_engine(engine, options)
            release = options['release']
            component = argv[2]
            abort(Simp::Metadata.critical("Must specify Release from which to remove component")[0]) unless options['release']
            engine.releases[release].delete_component(component)
          else
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release component [ add | delete ]'
              opts.banner << '    Add or delete component for the specified release.'
            end
          abort(Simp::Metadata.critical("Invalid subcommand: `simp-metadata release component` expects 'add' or 'delete'`")[0])
          end

          when 'platforms'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release <release_name> platforms'
              opts.banner += "\n-Outputs valid platforms for specified release."
            end
            engine, root = get_engine(engine, options)
            if options['metadata_version'] == 'v1'
              Simp::Metadata.critical('Platform data is not available for metadata version 1')
            else
              puts engine.releases[options['release']].platforms.keys.join("\n")
            end

          when 'puppet_versions'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata puppet_release <release_name> puppet_versions'
              opts.banner += "\n-Outputs Puppet versions for specified release."
            end
            engine, root = get_engine(engine, options)
            if options['metadata_version'] == 'v1'
              Simp::Metadata.critical('Puppet versions are not available for metadata version 1')
            else
              puts engine.releases[options['release']].puppet_versions.output
            end

          when 'isos'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release <release_name> isos'
              opts.banner += "\n-Creates a list of base ISOs that this version of SIMP can utilize."
            end
            engine, root = get_engine(engine, options)
            if options['metadata_version'] == 'v1'
              Simp::Metadata.critical('ISO data is not available for metadata version 1')
            else
              platform = argv[1]
              if platform
                output = engine.releases[options['release']].platforms[platform].images
              else
                output = engine.releases[options['release']].isos.keys
              end
              puts output
            end

          when 'puppetfile'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release <release_name> puppetfile'
              opts.banner += "\n-Creates a Puppetfile based on the version specified."
            end
            engine, root = get_engine(engine, options)
            type = argv[1]
            puts engine.releases[options['release']].puppetfile('type' => type)

          when 'diff'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release diff <release 1> <release 2> [attribute]'
              opts.banner += "\n-Shows differences between specified releases (attribute can be specified)."
            end
            engine, root = get_engine(engine, options)
            release1 = argv[1]
            release2 = argv[2]
            attribute = argv[3]
            release1 = engine.releases[release1]
            release2 = engine.releases[release2]
            diff = release1.diff(release2, attribute)
            puts diff.to_yaml

          else
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release [ components | diff ]'
            end
            puts 'components:'
            engine.releases[options['release']].components.keys.each do |line|
              puts "    #{line}"
            end
          end

          engine.save((['simp-metadata', 'release'] + argv).join(' ')) if root
        rescue RuntimeError => e
          Simp::Metadata.critical(e.message)
          exit 5
        end
      end
    end
  end
end
