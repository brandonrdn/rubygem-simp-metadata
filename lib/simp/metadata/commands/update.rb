require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Class to update a component's attributes
      class Update < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root

        def description
          'Update a components attributes'
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata update <component> <setting> <value>'
            opts.banner << "  #{description}"
          end

          @engine, @root = get_engine(engine, options)

          begin
            component = argv[0]
            setting = argv[1]
            value = argv[2]
            object = if options[:release].nil?
                       @engine.sources[component]
                     else
                       @engine.releases[options[:release]].sources[component]
                     end

            unless object.methods.include?(setting.to_sym)
              Simp::Metadata.critical("#{setting} is not a valid setting")
              exit 7
            end

            begin
              object.send("#{setting}=".to_sym, value)
            rescue NoMethodError => e
              Simp::Metadata.critical(e.message)
              Simp::Metadata.backtrace(e.backtrace)
              Simp::Metadata.critical("#{setting} is a read-only setting")
              exit 6
            end

            @engine.save(([:simp_metadata, 'update'] + argv).join(' ')) if @root
          rescue RuntimeError => e
            Simp::Metadata.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end
