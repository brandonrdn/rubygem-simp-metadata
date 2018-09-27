require 'simp/metadata/components'
require 'simp/metadata/release'
require 'simp/metadata/platforms'
require 'httparty'
require 'ruby-progressbar'
require 'find'
require 'fileutils'

module Simp
  module Metadata
    class Build < Component
      include Enumerable
      attr_accessor :engine
      attr_accessor :release_version
      attr_accessor :iso
      attr_accessor :build_dir
      attr_accessor :currentdir
      attr_accessor :options

      ###Eventually need to move build commands out of this file to make the files smaller and more organized
      #       def build_commands
      #         if @build_commands.nil?
      #         @build_commands = Simp::Metadata::Build_commands.new(engine, edition)
      #         end
      #         @build_commands
      #       end

      def initialize(engine, name, version)
        @engine = engine
        @name = name
        @release_version = version
      end

      def to_s
        name
      end

      def options
        engine.options
      end

      def stage_header(text)
        length = text.length + 8
        puts
        puts "#" * length
        puts "##  #{text}  ##"
        puts "#" * length
        puts
      end

      def verbose
        options['verbose']
      end

      def currentdir
        if @currentdir.nil?
          @currentdir = Dir.pwd
        end
        @currentdir
      end

      def iso
        if @iso
          @iso.to_s
        else
          iso_names.each do |name|
            @iso = name
            if primary?(iso)
              name
            end
          end
        end
      end

      def components
        engine.releases[release].components
      end

      def destination
        if options['destination']
          options['destination']
        else
          Dir.pwd
        end
      end

      def release
        options['release']
      end

      def preserve
        if options['preserve']
          options['preserve']
        end
      end

      def os_version
        #if options['os_version']
        #  options['os_version']
        #else
        #  'el7'
        #end
        "el#{iso.split('-')[1].chr}"
      end

      def build_version
        options['build_os_version']
      end

      def el_version
        os_version[-1]
      end

      def os_family
        iso.split('-')[0]
      end

      def build_dir
        currentdir
        if @build_dir.nil?
          if options['build_dir']
            @build_dir = options['build_dir']
          else
            @build_dir = "#{currentdir}/build"
          end
        end
        @build_dir
      end

      def output_dirs
        output = []
        %w(isos rpms tarballs built_rpms packages).each {|dir| output.push("#{build_dir}/#{dir}")}
        output
      end

      def rpm_cache
        if options['rpm_cache']
          path = options['rpm_cache']
          if path =~ /^\.\/.+$/
            add_path = path.split('./')[-1]
            rpm_cache = "#{currentdir}/#{add_path}"
          else
            rpm_cache = options['rpm_cache']
          end
        else
          rpm_cache = "#{currentdir}/rpms"
        end
        rpm_cache
      end

      def iso_cache
        if options['iso_cache']
          path = options['iso_cache']
          if path =~ /^\.\/.+$/
            add_path = path.split('./')[-1]
            iso_cache = "#{currentdir}/#{add_path}"
          else
            iso_cache = options['iso_cache']
          end
        else
          iso_cache = "#{currentdir}/ISO"
        end
        iso_cache
      end

      def tar_cache
        if options['tar_cache']
          path = options['tar_cache']
          if path =~ /^\.\/.+$/
            add_path = path.split('./')[-1]
            tar_cache = "#{currentdir}/#{add_path}"
          else
            tar_cache = options['tar_cache']
          end
        else
          tar_cache = "#{currentdir}/tarballs"
        end
        tar_cache
      end

      def build_iso_dir
        "#{build_dir}/isos"
      end

      def build_tarball_dir
        "#{build_dir}/tarballs"
      end

      def build_rpm_dir
        "#{build_dir}/rpms"
      end

      def create_build_dirs
        FileUtils.makedirs(build_dir)
        output_dirs.each {|dir| FileUtils.makedirs(dir)}
      end

      def edition
        options['edition']
      end

      def local_isos
        Dir.entries(iso_cache).reject {|file| File.directory?(file) || file[0].include?('.')}
      end

      def prefix
        if edition == 'enterprise'
          'SIMP-Enterprise'
        else
          'SIMP'
        end
      end

      def component_tarball_name
        "#{prefix}-#{release}.#{os_version}-components.tar.gz"
      end

      def package_tarball_name
        "#{prefix}-#{release}.#{os_version}-package.tar.gz"
      end

      def built_rpm_tarball_name
        "#{prefix}-#{release}.#{os_version}-built_rpms.tar.gz"
      end

      def build_tarball_name
        "simp-bootable-config-#{os_family}-#{el_version}.tar.gz"
      end

      def overlay_tarball_name
        "#{prefix}-#{release}.#{os_version}-#{os_family}-#{el_version}-x86_64.tar.gz"
      end

      def iso_name
        "#{prefix}-#{release}.#{os_version}-#{platform}.iso"
      end

      def build_purge
        build_dirs.each do |folder|
          FileUtils.remove folder, :force => true
        end
      end

      def verify_commands
        commands = %w(isoinfo createrepo)
        commands.each do |command|
          abort(Simp::Metadata.critical("#{command} is not installed. Please install and try again")[0]) unless command?(command)
        end
      end

      def build_assets_repo
        "https://download.simp-project.com/simp/ISO/build_assets/simp6/el/#{el_version}/x86_64"
      end

      def tar_yum_repo
        "https://download.simp-project.com/simp/ISO/tar_bundles"
      end

      def makerepo(dir)
        Dir.chdir(dir) do
          system("chmod -fR u+rwX,g+rX,o=g .")
          FileUtils.copy(Dir.glob("repodata/*comps*.xml").first, "simp_comps.xml")
          system("createrepo -p -g simp_comps.xml .")
          FileUtils.remove("simp_comps.xml")
        end
      end

      def get_rpm(component, dir = nil)
        build_types = ['puppet-module', 'rubygem']
        rpm_name = component.rpm_name
        arch = component.target
        type = component.component_type
        return unless build_types.include?(type)
        dest = if dir == nil
                 "./SIMP/#{arch}"
               else
                 dir
               end
        FileUtils.makedirs(dest)
        component.download(dest, options['source'])
        return if File.exist?("#{dest}/#{rpm_name}")
        component.build(dest) unless File.exist?("#{dest}/#{rpm_name}")
        FileUtils.cp("#{dest}/#{rpm_name}", "#{build_dir}/built_rpms")
        Simp::Metadata.critical("#{rpm_name} NOT FOUND") unless File.exist?("#{dest}/#{rpm_name}")
      end

      def component_tarball_build
        # Attempt to Download
        download(build_tarball_dir, build_assets_repo, component_tarball_name)
        return if File.exist?("#{build_tarball_dir}/#{component_tarball_name}")

        stage_header("Creating #{component_tarball_name}")

        # Create temp dir
        Dir.mktmpdir do |dir|
          Dir.chdir(dir)

          # Download Components
          components.each do |comp|
            get_rpm(comp, nil)
          end

          # Create Tarball
          system("tar -cvzf #{build_tarball_dir}/#{component_tarball_name}")
        end
      end

      def built_rpm_tarball_build
        Dir.chdir("#{build_dir}/built_rpms") do
          Simp::Metadata.run("tar -cvzf #{build_tarball_dir}/#{built_rpm_tarball_name} ./")
        end
      end

      def package_tarball_build
        Dir.chdir("#{build_dir}/packages") do
          Simp::Metadata.run("tar -cvzf #{build_tarball_dir}/#{package_tarball_name} ./")
        end
      end

      def build_tarball_build
        # Attempt to Download
        download(build_tarball_dir, build_assets_repo, component_tarball_name)
        return if File.exist?("#{build_tarball_dir}/#{component_tarball_name}")
        ##### ADD Way To Build From SOURCE!
      end

      def overlay_tarball_build
        download(build_tarball_dir, tar_yum_repo, overlay_tarball_name)
        return if File.exist?("#{build_tarball_dir}/#{overlay_tarball_name}")
        component_tarball_build unless File.exist?("#{build_tarball_dir}/#{component_tarball_name}")
        build_tarball_build unless File.exist?("#{build_tarball_dir}/#{build_tarball_name}")
        Dir.mktmpdir do |dir|
          Dir.chdir(dir)
          FileUtils.cp "#{build_tarball_dir}/#{build_tarball_name}", dir
          FileUtils.cp "#{build_tarball_dir}/#{component_tarball_build}", dir
          system("tar xvf *.tar.gz ./")
          FileUtils.remove("#{dir}/*.tar.gz")
          system("tar -cvzf #{build_tarball_dir}/#{overlay_tarball_name} #{dir}")
        end
        abort(Simp::Metadata.critical("Failed to create Overlay Tarball #{overlay_tarball_name}")[0]) unless File.exist?("#{build_tarball_dir}/#{overlay_tarball_name}")
      end

      def platforms
        result = {}
        engine.releases[release].isos.each do |_name, data|
          result[data['platform']] = true unless result.keys.include?(data['platform'])
        end
        result.keys
      end

      def build_distribution
        options['distribution']
      end

      def platform
        engine.isos[iso].platform
      end

      def validate_size(iso)
        local = File.size("#{iso_cache}/#{iso}").to_s
        compare = engine.isos[iso].size
        Simp::Metadata.warning("local file #{iso}: size #{local} does not match valid size #{compare}")[0] unless local.eql?(compare)
      end

      def validate_checksum(iso)
        sha256 = Digest::SHA256.file "#{iso_cache}/#{iso}"
        local = sha256.to_s
        compare = engine.isos[iso].checksum
        Simp::Metadata.warning("local file #{iso}: checksum #{local} does not match valid checksum #{compare}")[0] unless local.eql?(compare)
      end

      def validate_rpm(rpm, clean = true)
        exitcode = Simp::Metadata.run("rpm -K --nosignature #{rpm} 2>&1 > /dev/null")

        unless exitcode == 0
          error = "RPM #{rpm} is invalid"

          if clean
            error += ', removing'
            FileUtils.rm(rpm) if File.exist?(rpm)
          end
          Simp::Metadata.critical(error)
        end
      end


      def dependency_check(iso)
        result = {iso => true}
        unless engine.isos[iso].dependencies.nil?
          engine.isos[iso].dependencies.each do |dep|
            result[dep] = true
          end
        end
        result.keys
      end

      def valid_isos
        engine.sources['simp-metadata'].isos.keys
      end

      def iso_names
        engine.isos.release_isos
      end

      def release_isos
        engine.releases[release].platforms
      end

      def validate_iso(iso)
        validate_size(iso)
        validate_checksum(iso)
      end

      def primary_iso
        if iso_names.size == 1
          iso_names
        else
          iso_names.each do |iso|
            if primary?(iso)
              iso
            end
          end
        end
      end

      def primary?(iso)
        result = nil
        if engine.isos[iso].primary
          result = true
        end
        result
      end

      def buildable_isos
        result = []
        if options['build_iso']
          @iso = options['build_iso']
          result.push(options['build_iso']) if primary?(iso)
        else
          local_isos.each do |iso|
            next if iso.match?('SIMP-')
            if local_isos.include?(iso) && valid_isos.include?(iso)
              result.push(iso) if primary?(iso)
            end
          end
        end
        result
      end

      def iso_build_command
        heredoc = <<-HEREDOC
mkisofs
-A SIMP-#{release}
-V SIMP-#{release}
-volset SIMP-#{release}
-uid 0
-gid 0
-J
-joliet-long
-r
-v
-T
-b isolinux/isolinux.bin
-c boot.cat
-boot-load-size 4
-boot-info-table
-no-emul-boot
-eltorito-alt-boot
-e images/efiboot.img
-no-emul-boot
-m TRANS.TBL
-x ./lost+found
-o #{iso_name}
#{extract_dir}
        HEREDOC
        heredoc.tr("\n", ' ')
      end

      def package_purge(package_dir)
        prune_count = 0
        Dir.glob("#{package_dir}/*.rpm").each do |package|
          package_name = `rpm -qp --qf "%{NAME}" #{package} 2>/dev/null`.chomp
          unless package_list.include?(package_name)
            FileUtils.remove package
            prune_count += 1
          end
        end
        puts "Info: Pruned #{prune_count} packages from #{package_dir}"
      end

      def package_list
        packages = []
        File.open("#{__dir__}/../../../#{el_version}-pkglist.txt").each {|package| packages << package.chomp}
        packages
      end

      def command?(command)
        system("which #{ command} > /dev/null 2>&1")
      end

      def extract_dir
        "#{build_dir}/ISOs/extract"
      end

      def extract_iso(iso, path)
        prune_count = 0
        iso_files = `isoinfo -Rf -i #{iso}`.split("\n")

        # Progress Bar
        iso_files.each do |iso_entry|
          iso_files.delete(File.dirname(iso_entry))
        end
        progress = ProgressBar.create(:title => 'Unpacking', :total => iso_files.size)
        # End Progress Bar

        # Extract Files
        iso_files.each do |iso_entry|
          target = "#{path}#{iso_entry}"
          unless File.exist?(target)
            FileUtils.makedirs(File.dirname(target))
            system("isoinfo -R -x #{iso_entry} -i #{iso} > #{target}")
          end
          if progress
            progress.increment
          else
            print "#"
          end
        end
      end

      def repoclosure(dir)
        _verbose = ENV.fetch('SIMP_PKG_verbose', 'no') == 'yes'
        _repoclose_pe = ENV.fetch('SIMP_PKG_repoclose_pe', 'no') == 'yes'

        yum_conf_template = <<-HEREDOC
[main]
keepcache=0
exactarch=1
obsoletes=1
gpgcheck=0
plugins=1
installonly_limit=5
<% unless #{_repoclose_pe} -%>
exclude=*-pe-*
<% end -%>

<% repo_files.each do |repo| -%>
include=file://<%= repo %>
<% end -%>
        HEREDOC

        yum_repo_template = <<-HEREDOC
[<%= repo_name %>]
name=<%= repo_name %>
baseurl=file://<%= repo_path %>
enabled=1
gpgcheck=0
protect=1
        HEREDOC

        fail("#{dir} does not exist!") unless File.directory?(dir)

        Dir.mktmpdir do |temp_dir|
          Dir.chdir(temp_dir) do
            FileUtils.makedirs('repos/base')

            Dir.glob(dir).each do |base_dir|
              Find.find(base_dir) do |path|
                if (path =~ /.*\.rpm$/) and (path !~ /.*.src\.rpm$/)
                  sym_path = "repos/base/#{File.basename(path)}"
                  FileUtils.ln_s(path, sym_path, :verbose => _verbose) unless File.exists?(sym_path)
                end
              end
            end

            repo_files = []
            Dir.glob('repos/*').each do |repo|
              if File.directory?(repo)
                Dir.chdir(repo) {%x{createrepo .}}

                repo_name = File.basename(repo)
                repo_path = File.expand_path(repo)
                conf_file = "#{temp_dir}/#{repo_name}.conf"

                File.open(conf_file, 'w') do |file|
                  file.write(ERB.new(yum_repo_template, nil, '-').result(binding))
                end

                repo_files << conf_file
              end
            end

            File.open('yum.conf', 'w') do |file|
              file.write(ERB.new(yum_conf_template, nil, '-').result(binding))
            end

            cmd = 'repoclosure -n -t -r base -c yum.conf'

            if verbose
              stage_header("Running #{cmd} in path #{Dir.pwd}")
            end

            output = %x(#{cmd})

            if !$?.success? || (output =~ /nresolved/)
              errmsg = ['Error: REPOCLOSURE FAILED:']
              errmsg << [output]
              abort(errmsg.join("\n"))
            end
          end
        end
      end

      def iso_build(buildable_isos)
        # Grab build ISO
        buildable_isos.each do |build_iso|
          @iso = build_iso

          # Skip ISO if it doesn't match specified build platform
          if build_distribution
            next unless platform.include?(build_distribution)
          end

          if build_version
            next if el_version != build_version
          end

          if File.exist?("#{build_iso_dir}/#{iso_name}")
            stage_header("SIMP ISO #{iso_name} already exists! Not building for existing ISO")
            next
          end

          stage_header("Starting build for #{platform}")

          # Create Build Directories
          create_build_dirs

          # Create tempdir
          FileUtils.makedirs(extract_dir)
          Dir.chdir(extract_dir) do
            # Check for ISO dependencies
            stage_header("Checking Dependencies for ISO #{iso}")
            isos = dependency_check(build_iso)
            if isos.length > 1
              puts "INFO: Dependencies found for #{build_iso}"
              puts "INFO: Utilizing ISOS: #{isos.to_s}"
            else
              puts "INFO: No dependencies found for #{build_iso}"
            end

            # Build SIMP ISO
            isos.each do |iso|

              # Validate ISO
              stage_header("Validating ISO #{iso}")
              validate_iso(iso)

              # Extract ISO
              stage_header("Extracting ISO #{iso}")
              extract_iso("#{iso_cache}/#{iso}", extract_dir)
            end

            # Add Overlay tarball
            stage_header("Adding SIMP Overlay Tarball")
            if options['overlay_tarball']
              if File.exist?("#{tar_cache}/#{overlay_tarball_name}")
                `tar -xvf "#{tar_cache}/#{overlay_tarball_name}"`
              else
                overlay_tarball_build
                `tar -xvf #{build_tarball_dir}/#{overlay_tarball_name}`
              end
            else
              overlay_tarball_build
              `tar -xvf #{build_tarball_dir}/#{overlay_tarball_name}`
            end

            # Add Build tarball
            stage_header('Adding SIMP Build Tarball')

            # Grab necessary packages
            stage_header("Downloading Packages")
            packages = []
            File.open("#{__dir__}/../../../#{os_family}-#{el_version}-packages.yaml").each {|package| packages << package.chomp}

            packages.each do |package|
              packages.delete(File.dirname(package))
            end
            progress = ProgressBar.create(:title => 'Downloading', :total => packages.size)

            packages.each do |package|
              url = package.split(': ')[-1].chomp
              package_name = package.split(':')[0].chomp
              uri = URI.parse(url)
              file = File.basename(uri.path).chomp
              source = uri.to_s.reverse.split('/', 2).last.reverse
              valid_arch = ['noarch', 'x86_64', 'arm']
              arch = file.split('.rpm')[0].split('.')[-1].chomp
              dest = if valid_arch.include?(arch)
                       "#{extract_dir}/SIMP/#{arch}"
                     else
                       "#{extract_dir}/SIMP/noarch"
                     end
              if valid_arch.include?(arch) && !Dir.exist?("#{extract_dir}/SIMP/#{arch}")
                FileUtils.makedirs("#{extract_dir}/SIMP/#{arch}")
              end
              archive_dirs = ["https://download.simp-project.com/simp/archive/yum/Releases/#{release}/#{os_version.upcase}/core", "https://download.simp-project.com/simp/archive/yum/Releases/#{release}/#{os_version.upcase}/dependencies"]
              archive_dirs.each do |archive|
                download(dest, archive, file)
              end
              download(dest, source, file) unless File.exist?("#{dest}/#{file}")
              FileUtils.copy "#{dest}/#{file}", "#{build_dir}/packages" if File.exist?("#{dest}/#{file}")

              Simp::Metadata.critical("#{file} NOT FOUND") unless File.exist?("#{dest}/#{file}")
              if progress
                progress.increment
              else
                print "#"
              end
            end

            # Purge package folders
            stage_header("Pruning unneeded packages")
            package_purge("#{extract_dir}/Packages")

            # Createrepo
            dirs = [
                "#{extract_dir}/SIMP/noarch",
                "#{extract_dir}/SIMP/x86_64",
                "#{extract_dir}/Packages"
            ]

            dirs.each do |dir|
              Dir.chdir(dir) do
                `createrepo .`
              end
            end

            if preserve
              dirs.each do |dir|
                path = dir.split("#{extract_dir}/")[-1]
                FileUtils.makedirs("#{build_rpm_dir}/#{path}")
                rpms = Dir.glob(File.join(dir, '*.rpm'))
                rpms.each {|rpm| FileUtils.copy rpm, "#{build_rpm_dir}/#{path}"}
              end
            end

            # Repoclosure
            stage_header("Verifying dependencies")
            repoclosure(extract_dir)

            # make repo
            if iso == isos.last
              makerepo(extract_dir)
            end

            # Build tarballs
            built_rpm_tarball_build
            package_tarball_build

            # Create ISO
            stage_header("Creating #{iso_name}")
            Dir.chdir(build_iso_dir) do
              %x(#{iso_build_command})
            end
            stage_header("Finished building #{iso_name}")
          end

          # Move necessary files to final directory
          FileUtils.makedirs "#{currentdir}#{platform}"
          if preserve
            FileUtils.remove "#{extract_dir}"
            FileUtils.move build_dir, "#{currentdir}/#{platform}"
          else
            FileUtils.move Dir.glob(File.join(build_iso_dir, '*.iso')), "#{currentdir}/#{platform}"
            FileUtils.remove "#{build_dir}"
          end
        end
        stage_header("Finished Build Process")
      end

      def build(build_type, arg)

        $build_type = build_type

        case build_type
        when 'tarball'
          $tarball_type = arg
          case arg
          when 'component'
            component_tarball_build

          when 'build'


          when 'overlay'
          else
            abort(Simp::Metadata.critical('Invalid tarball type specified'))
          end

        when 'iso'
          verify_commands
          iso_build(buildable_isos)

        else
          abort(Simp::Metadata.critical("Invalid build type specified. Expected: tarball or iso")[0])
        end
      end
    end
  end
end
