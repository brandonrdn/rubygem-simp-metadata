require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Release < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          options = defaults(argv) do |opts,options|
            opts.banner = 'Usage: simp-metadata release <release_name> [components]'
            opts.banner = '       simp-metadata release diff <release1> <release2>'
          end
          engine, root = get_engine(engine, options)
          begin
            section = argv[0]

            case section
            when 'components'
              puts engine.releases[options['release']].components.keys.join("\n")

            when 'puppetfile'
              type = argv[1]
              puts engine.releases[options['release']].puppetfile('type' => type)

            when 'diff'
              release1 = argv[1]
              release2 = argv[2]
              attribute = argv[3]
              release1 = engine.releases[release1]
              release2 = engine.releases[release2]
              diff = release1.diff(release2, attribute)
              puts diff.to_yaml
            else
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
end
