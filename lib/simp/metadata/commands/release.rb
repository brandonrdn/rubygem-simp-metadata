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
              opts.banner = 'Usage: simp-metadata release [ components | diff ]'
            end

          when 'components'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata release <release_name> components'
              opts.banner += "\n-Creates a clean list of only the component names for the specified release."
            end
            engine, root = get_engine(engine, options)
            puts engine.releases[options['release']].components.keys.join("\n")

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

        rescue RuntimeError => e
          Simp::Metadata.critical(e.message)
          exit 5
        end
      end
    end
  end
end
