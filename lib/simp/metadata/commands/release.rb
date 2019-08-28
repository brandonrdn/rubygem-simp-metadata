require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Release Class to view and manage SIMP Releases
      class Release < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root

        def description
          'View, compare, and edit components of release(s)'
        end

        def valid_subcommands
          %w[components diff add_component delete_component platforms puppet_versions isos puppetfile]
        end

        def help
          defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata release [subcommand]'
            opts.banner << "  #{description}"
            opts.banner << "  subcommands:"
            valid_subcommands.each { |cmd| opts.banner << "    - #{cmd}" }
          end
        end

        def components
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata release <release_name> components'
            opts.banner += "\n-Creates a clean list of only the component names for the specified release."
          end
          @engine, @root = get_engine(engine, options)
          puts engine.releases[options[:release]].components.keys.join("\n")
        end

        def component_add
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata release component add <-v release> <component_name> <setting>=<value>'
            opts.banner << '    Adds a SIMP component for a specific release'
            opts.banner << '      - Must include at least one setting (ref, tag, or branch)'
            opts.banner << '      - Can pass multiple setting=value sets'
          end
          @engine, @root = get_engine(engine, options)
          release = options[:release]
          _command, _subcommand, component, *input = argv
          hash = {}
          input.each do |settings|
            setting = settings.split('=')[0]
            value = settings.split('=')[-1]
            hash[setting] = value
          end
          new_data = {}
          %w[ref tag branch].each { |key| new_data[key] = hash[key] if hash[key] }
          begin
            engine.releases[release].add_component(component, new_data)
          rescue StandardError => e
            Simp::Metadata.critical(e.message)
            Simp::Metadata.backtrace(e.backtrace)
          end
          # critical("Must include at least one setting in hash form. i.e. {'tag' => '1.2.3'}")[0]) unless argv[2]
          # critical("Must specify Release from which to remove component")[0]) unless options[:release]
        end

        def component_delete
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata release component delete <-v release> <component_name>'
            opts.banner << '    Removes a SIMP component from a specific release'
          end
          @engine, @root = get_engine(engine, options)
          release = options[:release]
          component = argv[2]
          abort(Simp::Metadata.critical("Must specify Release to remove component")[0]) unless options[:release]
          engine.releases[release].delete_component(component)
        end

        def component
          sub_subcommand = argv[1]
          case sub_subcommand
          when '-h', '--help', 'help'
            defaults(argv) { |opts, _options| opts.banner = 'Usage: simp-metadata release component [ add | delete ]' }
          when 'add'
            component_add
          when 'delete'
            component_delete
          else
            defaults(argv) do |opts, _options|
              opts.banner = 'Usage: simp-metadata release component [ add | delete ]'
              opts.banner << '    Add or delete component for the specified release.'
            end
            abort(Simp::Metadata.critical("Invalid subcommand: expects 'component add' or 'component delete'`")[0])
          end
        end

        def platforms
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata release <release_name> platforms'
            opts.banner += "\n-Outputs valid platforms for specified release."
          end
          @engine, @root = get_engine(engine, options)
          if options[:metadata_version] == 'v1'
            Simp::Metadata.critical('Platform data is not available for metadata version 1')
          else
            puts engine.releases[options[:release]].platforms.keys.join("\n")
          end
        end

        def puppet_versions
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata puppet_release <release_name> puppet_versions'
            opts.banner += "\n-Outputs Puppet versions for specified release."
          end
          @engine, @root = get_engine(engine, options)
          if options[:metadata_version] == 'v1'
            Simp::Metadata.critical('Puppet versions are not available for metadata version 1')
          else
            puts engine.releases[options[:release]].puppet_versions.output
          end
        end

        def isos
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata release <release_name> isos'
            opts.banner += "\n-Creates a list of base ISOs that this version of SIMP can utilize."
          end
          @engine, @root = get_engine(engine, options)
          if options[:metadata_version] == 'v1'
            Simp::Metadata.critical('ISO data is not available for metadata version 1')
          else
            platform = argv[1]
            output = if platform
                       engine.releases[options[:release]].platforms[platform].images
                     else
                       engine.releases[options[:release]].isos.keys
                     end
            puts output
          end
        end

        def puppetfile
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata release <release_name> puppetfile'
            opts.banner += "\n-Creates a Puppetfile based on the version specified."
          end
          @engine, @root = get_engine(engine, options)
          type = argv[1]
          puts engine.releases[options[:release]].puppetfile(type: type)
        end

        def diff
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata release diff <release 1> <release 2> [attribute]'
            opts.banner += "\n-Shows differences between specified releases (attribute can be specified)."
          end
          @engine, @root = get_engine(engine, options)
          release1 = argv[1]
          release2 = argv[2]
          attribute = argv[3]
          release1 = engine.releases[release1]
          release2 = engine.releases[release2]
          diff = release1.diff(release2, attribute)
          puts diff.to_yaml
        end

        def save
          @engine.save(([:simp_metadata, 'release'] + argv).join(' ')) if @root
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
