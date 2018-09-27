require_relative '../commands'
module Simp
  module Metadata
    module Commands
      class Build < Simp::Metadata::Commands::Base
        def run(argv, engine = nil)
          subcommand = argv[0]

          case subcommand
          when '--help', '-h'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata build <iso|tarball> [options]'
            end

          when 'iso'
            options = defaults(argv) do |opts, options|
              opts.banner = 'Usage: simp-metadata build iso [-v <release>] [-p <el6|el7>] [-d <os_family>]'
              opts.on('-d', '--os_family', 'Distribution to use (CentOS or RedHat)') do |distro|
                options['os_family'] = distro
              end
              opts.on('-T', '--tar_cache [folder]', 'Folder to cache tarballs during build (pre-existing tarballs will be used in the build') do |tar_cache|
                options['tar_cache'] = tar_cache
              end
              opts.on('-R', '--rpm_cache [folder]', 'Folder to cache RPMs during build (pre-existing RPMs will be used in the build') do |rpm_cache|
                options['rpm_cache'] = rpm_cache
              end
              opts.on('-I', '--iso_cache [folder]', 'Folder to cache ISOs during the build (build ISOs should be placed here)') do |iso_cache|
                options['iso_cache'] = iso_cache
              end
              opts.on('-B', '--build_iso [iso]', 'Specify ISO to use for build (Default: Build all available ISOs in iso_cache') do |build_iso|
                options['build_iso'] = build_iso
              end
              opts.on('-O', '--overlay_tarball', 'Uses pre-existing overlay tarball for ISO build. Default: Build tarball from scratch') do |overlay|
                options['overlay_tarball'] = overlay
              end
              opts.on('-V', '--verbose', 'Detailed output for all commands') do |verbose|
                options['verbose'] = verbose
              end
            end
            engine, root = get_engine(engine, options)
            simp_build = Simp::Metadata::Build.new(engine, nil, options['edition'])
            simp_build.build('iso', nil)

          when 'tarball'
            options = defaults(argv) do |opts, options|
              opts.banner = "Usage: simp-metadata build tarball [-v <release>] [-p <el6|el7>] [-d <os_family>] [ release | component | build ]\n\n"
              opts.banner << "  Tarball Types:\n"
              opts.banner << "     component: Builds a tarball of release components with the SIMP/noarch structure\n"
              opts.banner << "     build: Creates a tarball of build files\n"
              opts.banner << "     overlay: Builds the entire overlay tarball(default)\n\n"
              opts.on('-d', '--os_family [distro]', 'Distribution to use: CentOS, RedHat') do |distro|
                options['os_family'] = distro
              end
              options['build_dir'] = Dir.pwd
              opts.on('-b', '--build_dir [folder]', 'Directory to build in (Default: ./build') do |build_dir|
                options['build_dir'] = build_dir
              end
              options['source'] = []
              opts.on('-s', '--source [path/url]', 'URL or path to grab RPMs from (can be passed more than once)') do |source|
                options['source'] << source
              end
              opts.on('-T', '--tar_cache [folder]', 'Folder to cache tarballs during build (pre-existing tarballs will be used in the build') do |tar_cache|
                options['tar_cache'] = tar_cache
              end
              opts.on('-R', '--rpm_cache [folder]', 'Folder to cache RPMs during build (pre-existing RPMs will be used in the build') do |rpm_cache|
                options['rpm_cache'] = rpm_cache
              end
              opts.on('-p', '--preserve', 'Preserves the build directory and all files used during build') do |preserve|
                options['preserve'] = preserve
              end
            end
            engine, root = get_engine(engine, options)
            tarball_type = argv[1]

            simp_build = Simp::Metadata::Build.new(engine, nil, options['edition'])

            type = if tarball_type.nil?
                     'overlay'
                   else
                     tarball_type
                   end
            simp_build.build('tarball', type)
          else
            abort("Cannot build #{subcommand}")
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
