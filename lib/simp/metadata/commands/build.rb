require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Command to build SIMP deliverables
      class Build < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root

        def description
          'Build release ISO and Tarballs'
        end

        def default_options
          defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata build <iso|tarball> [options]'
            opts.banner << "  #{description}"
          end
        end

        def set_options(message)
          defaults(argv) do |parser, options|
            parser.banner = message
            parser.on('-D', '--distribution [distribution]', 'Distribution to build (CentOS or RedHat)') { |distribution| options[:distribution] = distribution }
            parser.on('-b', '--build_version', 'el_version to build') {|build_version| options[:build_version] = build_version }
            parser.on('-T', '--tar_cache DIR', 'Directory of tarballs used to build') { |tar_cache| options[:tar_cache] = tar_cache }
            parser.on('-R', '--rpm_cache DIR', 'Directory of RPMs to use during build') { |rpm_cache| options[:rpm_cache] = rpm_cache}
            parser.on('-I', '--iso_cache DIR', 'Directory of base ISOs to use for the build') { |iso_cache| options[:iso_cache] = iso_cache }
            parser.on('-B', '--build_iso ISO', 'Specify a single base ISO to use for build') { |build_iso| options[:build_iso] = build_iso }
            parser.on('-O', '--overlay_tarball', 'Uses pre-existing overlay tarball for ISO build.') { |overlay_tarball| options[:overlay_tarball] = overlay_tarball }
            parser.on('-V', '--verbose', 'Detailed output for all commands') { |verbose| options[:verbose] = verbose }
            parser.on('-P', '--preserve', 'Preserves the build directory and all files used during build') { |preserve| options[:preserve] = preserve }
            parser.on('-U', '--upstream-build', 'Internal option for building. Not for customer use') { |upstream_build| options[:upstream_build] = upstream_build }
          end
        end

        def build_iso
          options = set_options('Usage: simp-metadata build iso [-v RELEASE]')
          @engine, @root = get_engine(engine, options)
          simp_build = Simp::Metadata::Build.new(engine, options[:release], options[:el_version])
          simp_build.build('iso')
        end

        def build_tarball
          options = set_options('Usage: simp-metadata build tarball build [-v RELEASE]')
          @engine, @root = get_engine(engine, options)
          simp_build = Simp::Metadata::Build.new(engine, nil, options[:edition])
          simp_build.build('tarball')
        end

        def build_components
          options = set_options('Usage: simp-metadata build components [-v <release>][-D DISTRO]')
          @engine, @root = get_engine(engine, options)
          release = options[:release]
          build_dir = options[:build_dir] || "#{Dir.pwd}/build"
          abort(Simp::Metadata::Debug.critical("No release specified")[0]) unless release
          components = engine.releases[release].sources
          components.each do |component|
            unless options[:force]
              puts "RPM #{component.rpm_name} already exists. Skipping..." unless component.download_source.nil?
              next
            end
            component.build(build_dir)
          end
          puts "Built RPMs are located in #{build_dir}"
        end

        def build_component
          options = set_options('Usage: simp-metadata build component [-v RELEASE] COMPONENT')
          @engine, @root = get_engine(engine, options)
          release = options[:release]
          component_name = argv[1]
          build_dir = options[:build_dir] || Simp::Metadata::BuildHandler.rpm_cache
          abort(Simp::Metadata::Debug.critical("No release specified")[0]) unless release
          abort(Simp::Metadata::Debug.critical("No component specified")[0]) unless component_name
          component = engine.releases[release].sources[component_name]

          unless options[:force]
            if File.exist?("#{build_dir}/#{component.rpm_name}")
              exit(Simp::Metadata::Debug.critical("RPM #{component.rpm_name} already exists"))
            end
          end
          component.build(build_dir)
        end

        def save
          engine.save(([:simp_metadata, 'component'] + argv).join(' ')) if @root
        end

        def build_help
          default_options
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          subcommand = %w[-h --help help].include?(@argv[0]) ? 'help' : @argv[0]
          public_send("build_#{subcommand}")
          save
        rescue RuntimeError => e
          Simp::Metadata::Debug.critical(e.message)
          exit 5
        end
      end
    end
  end
end
