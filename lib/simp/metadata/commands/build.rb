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

        def options_hash
          {
            'distribution' => "'-d', '--distribution [distribution]', 'Distribution to build (CentOS or RedHat)'",
            'build_version' => "'-b', '--build_version', 'el_version to build'",
            'tar_cache' => "'-T', '--tar_cache [dir]', 'Directory of tarballs used to build'",
            'rpm_cache' => "'-R', '--rpm_cache [dir]', 'Directory of RPMs to use during build'",
            'iso_cache' => "'-I', '--iso_cache [dir]', 'Directory of base ISOs to use for the build'",
            'build_iso' => "'-B', '--build_iso [iso]', 'Specify a single base ISO to use for build'",
            'overlay_tarball' => "'-O', '--overlay_tarball', 'Uses pre-existing overlay tarball for ISO build.'",
            'verbose' => "'-V', '--verbose', 'Detailed output for all commands'",
            'preserve' => "'-P', '--preserve', 'Preserves the build directory and all files used during build'",
            'upstream_build' => "'-U', '--upstream-build', 'Internal option for building. Not for customer use'"
          }
        end

        def iso_builder
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata build iso [-v <release>]'
            options_hash.each { |name, settings| opts.on(settings) { |setting| options[name] = setting } }
          end

          @engine, @root = get_engine(engine, options)
          simp_build = Simp::Metadata::Build.new(engine, options[:release], options[:el_version])
          simp_build.build('iso')
        end

        def tarball_builder
          options = defaults(argv) do |opts, _options|
            opts.banner = "Usage: simp-metadata build tarball build [-v <release>]"
            options_hash.each { |name, settings| opts.on(settings) { |setting| options[name] = setting } }
          end
          @engine, @root = get_engine(engine, options)
          simp_build = Simp::Metadata::Build.new(engine, nil, options[:edition])
          simp_build.build('tarball')
        end

        def components_builder
          options = defaults(argv) do |opts, _options|
            opts.banner = "Usage: simp-metadata build components [-v <release>] [-p <el6|el7>] [-D <os_family>]\n\n"
            options_hash.each { |name, settings| opts.on(settings) { |setting| options[name] = setting } }
          end
          @engine, @root = get_engine(engine, options)
          release = options[:release]
          build_dir = options[:build_dir] || "#{Dir.pwd}/build"
          abort(Simp::Metadata.critical("No release specified")[0]) unless release
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

        def component_builder
          options = defaults(argv) do |opts, _options|
            opts.banner = "Usage: simp-metadata build component [-v <release>] [-p <el6|el7>] <component>\n\n"
            options_hash.each { |name, settings| opts.on(settings) { |setting| options[name] = setting } }
          end
          @engine, @root = get_engine(engine, options)
          release = options[:release]
          component_name = argv[1]
          build_dir = options[:build_dir] || Simp::Metadata::BuildHandler.rpm_cache
          abort(Simp::Metadata.critical("No release specified")[0]) unless release
          abort(Simp::Metadata.critical("No component specified")[0]) unless component_name
          component = engine.releases[release].sources[component_name]

          unless options[:force]
            if File.exist?("#{build_dir}/#{component.rpm_name}")
              exit(Simp::Metadata.critical("RPM #{component.rpm_name} already exists"))
            end
          end
          component.build(build_dir)
        end

        def save
          engine.save(([:simp_metadata, 'component'] + argv).join(' ')) if @root
        end

        def help
          default options
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          subcommand = %w[-h --help help].include?(@argv[0]) ? 'help' : @argv[0]
          public_send("#{subcommand}_builder")
          save
        rescue RuntimeError => e
          Simp::Metadata.critical(e.message)
          exit 5
        end
      end
    end
  end
end
