require 'simp/metadata/components'
require 'simp/metadata/release'
require 'simp/metadata/packages'
require 'simp/metadata/platforms'
require 'ruby-progressbar'
require 'find'
require 'fileutils'

module Simp
  module Metadata
    # noinspection ALL
    class Build < Build_handler
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

      def project_dir
        File.join(File.dirname(__FILE__), '../../../')
      end

      def stage_header(text)
        length = text.length + 8
        puts '', "#" * length, "##  #{text}  ##", "#" * length, ''
      end

      def verbose
        options[:verbose]
      end

      def release_type
        # Match prereleases to Alpha, Beta, RC, Nightly, and Unstable releases
        prereleases = [/.*-[Aa][Ll][Pp][Hh][Aa].*/, /.*-[Bb][Ee][Tt][Aa].*/, /.*-[Rr][Cc].*/, /^nightly-/, /unstable/]
        case release
        when *prereleases
          'prereleases'
        else
          'releases'
        end
      end

      def currentdir
        @currentdir = Dir.pwd if @currentdir.nil?
        @currentdir
      end

      def iso
        base_iso_names.each { |name| @iso = name if primary?(name) } unless @iso
        @iso
      end

      def destination
        options[:destination] ? options[:destination] : Dir.pwd
      end

      def release
        options[:release]
      end

      def components
        engine.releases[release].sources
      end

      def packages
        engine.packages
      end

      def preserve
        options[:preserve] ? options[:preserve] : nil
      end

      def os_version
        "el#{iso.split('-')[1].chr}"
      end

      def os_family
        iso.split('-')[0]
      end

      def build_version
        options[:build_os_version]
      end

      def el_version
        options[:el_version]
      end

      def build_dir
        currentdir
        if @build_dir.nil?
          if options[:build_dir]
            @build_dir = options[:build_dir]
          else
            @build_dir = "#{currentdir}/build"
          end
        end
        @build_dir
      end

      def output_dirs
        output = []
        %w(isos rpms tarballs unsigned_rpms packages).each {|dir| output.push("#{build_dir}/#{dir}")}
        output
      end

      def rpm_cache
        if options[:rpm_cache]
          path = options[:rpm_cache]
          if path =~ /^\.\/.+$/
            rpm_cache = "#{currentdir}/#{path.split('./')[-1]}"
          else
            rpm_cache = options[:rpm_cache]
          end
        else
          rpm_cache = "#{currentdir}/rpms"
        end
        rpm_cache
      end

      def iso_cache
        if options[:iso_cache]
          path = options[:iso_cache]
          if path =~ /^\.\/.+$/
            iso_cache = "#{currentdir}/#{path.split('./')[-1]}"
          else
            iso_cache = options[:iso_cache]
          end
        else
          iso_cache = "#{currentdir}/ISO"
        end
        iso_cache
      end

      def tar_cache
        if options[:tar_cache]
          path = options[:tar_cache]
          if path =~ /^\.\/.+$/
            tar_cache = "#{currentdir}/#{path.split('./')[-1]}"
          else
            tar_cache = options[:tar_cache]
          end
        else
          tar_cache = "#{currentdir}/tarballs"
        end
        tar_cache
      end

      def iso_dir
        "#{build_dir}/isos"
      end

      def tarball_dir
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
        options[:edition]
      end

      def base_isos
        Dir.entries(iso_cache).reject { |file| File.directory?(file) || file[0].include?('.') }
      end

      def prefix
        case edition
        when 'enterprise'
          'SIMP-Enterprise'
        else
          'SIMP'
        end
      end

      def overlay_tarball_name
        "#{prefix}-#{release}.#{os_version}-#{os_family}-#{el_version.split('el')[-1]}-x86_64.tar.gz"
      end

      def iso_name
        "#{prefix}-#{release}.#{os_version}-#{iso_platform}.iso"
      end

      def build_purge
        output_dirs.each { |folder| FileUtils.remove folder, :force => true }
      end

      def verify_commands
        commands = %w(isoinfo createrepo)
        commands.each do |command|
          abort(Simp::Metadata.critical("#{command} is not installed")[0]) unless command?(command)
        end
      end

      def build_assets_path
        "#{base_community_path}/ISO/build_assets"
      end

      def tar_yum_repo
        "#{base_community_path}/ISO/tar_bundles"
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
        build_types = ['puppet-module', 'rubygem', 'rpm']
        rpm_name = component.rpm_name
        type = component.component_type
        return unless build_types.include?(type)
        dest = dir.nil? ? Dir.pwd : dir

        FileUtils.makedirs(dest)

        # Download if it exists
        component.download(dest)
        return if File.exist?("#{dest}/#{rpm_name}")

        # Build if needed
        component.build(dest) unless File.exist?("#{dest}/#{rpm_name}")
        FileUtils.cp("#{dest}/#{rpm_name}", "#{build_dir}/unsigned_rpms")
        Simp::Metadata.critical("#{rpm_name} NOT FOUND") unless File.exist?("#{dest}/#{rpm_name}")
      end

      def overlay_tarball_build
        # Attempt to download
        #downloader(tar_yum_repo, overlay_tarball_name, tarball_dir)
        #return if File.exist?("#{tarball_dir}/#{overlay_tarball_name}")

        # Build if necessary
        stage_header("Creating Overlay Tarball for SIMP #{release_version}")

        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do

            # Copy RPM Cache if it exists
            noarch_dir = "#{tmpdir}/SIMP/noarch"
            FileUtils.makedirs "#{noarch_dir}" unless File.directory?("#{noarch_dir}")
            FileUtils.cp "#{options[:rpm_cache]}/*rpm", "#{noarch_dir}" if options[:rpm_cache]

            # Download Components
            components.each do |component|
              arch = component.target
              arch_dir = "#{tmpdir}/SIMP/#{arch}"
              FileUtils.makedirs("#{arch_dir}") unless File.directory?("#{arch_dir}")
              next if File.exist?("#{arch_dir}/#{component.rpm_name}")
              get_rpm(component, "#{arch_dir}")
            end

            # Get SIMP and SIMP DOC Base RPMs
            get_simp_rpm("#{noarch_dir}") unless File.exist?("#{noarch_dir}#{simp_rpm}")
            get_simp_doc_rpm("#{noarch_dir}") unless File.exist?("#{noarch_dir}#{simp_doc_rpm}")

            FileUtils.makedirs("#{tmpdir}/SIMP/GPGKEYS")

            # Grab DVD data from server
            dvd_data_path = "#{build_assets_path}/simp6/#{release_type}/#{release}/#{el_version}/x86_64/DVD"
            get_dvd_data(dvd_data_path, tmpdir)

            exitcode = Simp::Metadata.run("tar -cvzf #{tarball_dir}/#{overlay_tarball_name} ./")
            unless exitcode == 0
              abort(Simp::Metadata.critical("Failed to create Overlay Tarball for SIMP #{release_version}")[0])
            end
          end
        end
      end

      def platforms
        result = Hash.new
        engine.isos[release].each do |_name, data|
          result[data[:platform]] = true unless result.keys.include?(data[:platform])
        end
        result.keys
      end

      def build_distribution
        options[:distribution]
      end

      def platform
        engine.isos[iso].platform
      end

      def iso_platform
        platform =~ /CentOS-7/ ? platform.sub(/[7]\.[0-9]/, '7.0') : iso_platform
      end

      def validate_size(iso)
        local = File.size("#{iso_cache}/#{iso}").to_s
        compare = engine.isos[iso].size
        abort(Simp::Metadata.warning("#{iso}: Size mismatch. Expected: #{compare}")[0]) unless local.eql?(compare)
      end

      def validate_checksum(iso)
        sha256 = Digest::SHA256.file "#{iso_cache}/#{iso}"
        local = sha256.to_s
        compare = engine.isos[iso].checksum
        abort(Simp::Metadata.warning("#{iso}: Sha256 mismatch. Expected: #{compare}")[0]) unless local.eql?(compare)
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
        engine.isos[iso].dependencies.each { |dep| result[dep] = true } unless engine.isos[iso].dependencies.nil?
        result.keys
      end

      def valid_isos
        engine.sources[:simp_metadata].isos.keys
      end

      def base_iso_names
        names = []
        engine.isos.each do |iso|
          data = engine.isos[iso]
          names.push(iso) if data[:platform] == platform
        end
        names
      end

      def release_isos
        engine.releases[release].platforms
      end

      def validate_iso(iso)
        validate_size(iso)
        validate_checksum(iso)
      end

      def primary_iso
        result = nil
        if base_iso_names.size == 1
          result = base_iso_names
        else
          base_iso_names.each { |iso| result = iso if primary?(iso) }
        end
        result
      end

      def primary?(iso)
        engine.isos[iso].primary ? true : nil
      end

      def buildable_isos
        result = []
        case options
        when ->(opts) { opts[:build_iso] }
          @iso = options[:build_iso]
          result.push(options[:build_iso]) if primary?(@iso.to_s)
        else
          base_isos.each do |iso|
            next unless primary?(iso) && valid_isos.include?(iso)
            next if iso.match?('SIMP-')
            result.push(iso)
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

      def package_list(file = "#{extract_dir}/#{el_version.split('el')[-1]}-simp_pkglist.txt")
        packages = []
        File.open(file).each {|package| packages << package.chomp unless package =~ /#/}
        packages
      end

      def command?(command)
        system("which #{ command} > /dev/null 2>&1")
      end

      def extract_dir
        "#{build_dir}/tmp/extract"
      end

      def extract_iso(iso, path)
        iso_files = `isoinfo -Rf -i #{iso}`.split("\n")

        # Progress Bar
        iso_files.each do |iso_entry|
          iso_files.delete(File.dirname(iso_entry))
        end
        progress = ProgressBar.create(:title => 'Unpacking', :total => iso_files.size)
        # End Progress Bar

        # Extract Files
        iso_files.each do |iso_entry|
          target = "#{path}/#{iso_entry}"
          unless File.exist?(target)
            FileUtils.makedirs(File.dirname(target))
            Simp::Metadata.run("isoinfo -R -x #{iso_entry} -i #{iso} > #{target}")
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

            stage_header("Running repoclosure")

            output = %x(#{cmd})

            if !$?.success? || (output =~ /unresolved/)
              errmsg = ['Error: REPOCLOSURE FAILED:']
              errmsg << [output]
              abort(errmsg.join("\n"))
            end
          end
        end
      end

      def iso_build(buildable_isos)
        buildable_isos.each do |iso|
        @iso = iso

          # Skip ISO if it doesn't match specified build platform
          next unless platform.include?(build_distribution) if build_distribution
          next if el_version != build_version if build_version

          if File.exist?("#{iso_dir}/#{iso_name}")
            puts "### SIMP ISO #{iso_name} already exists! Not building for existing ISO"
            next
          end

          stage_header("Starting build for #{platform}")

          # Create Build Directories
          create_build_dirs

          # Create Platform dir for files
          FileUtils.makedirs "#{currentdir}/#{platform}"

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
            stage_header("Adding SIMP Overlay Tarball for SIMP #{release_version}")

            build_tarball = true
            extract_dir = nil
            if options[:overlay_tarball] && File.exist?("#{tar_cache}/#{overlay_tarball_name}")
              extract_dir = tar_cache
              build_tarball = false
            end

            # Build Tarball if  needed
            overlay_tarball_build if build_tarball == true

            # Copy Files
            FileUtils.cp "#{extract_dir}/#{overlay_tarball_name}", "#{currentdir}/#{platform}"
            `tar -xvf #{extract_dir}/#{overlay_tarball_name}`

            # Grab necessary packages
            stage_header("Downloading Packages")

            progress = ProgressBar.create(:title => 'Progress', :total => packages.size)

            packages.each do |package|
              source = package.source
              file = package.rpm_name
              repo = package.repo
              valid_arch = ['noarch', 'x86_64', 'arm']
              arch = file.split('.rpm')[0].split('.')[-1].chomp
              dest = valid_arch.include?(arch) ? "#{extract_dir}/SIMP/#{arch}" : "#{extract_dir}/SIMP/noarch"
              if valid_arch.include?(arch) && !Dir.exist?("#{extract_dir}/SIMP/#{arch}")
                FileUtils.makedirs("#{extract_dir}/SIMP/#{arch}")
              end

              # Grab from repos if available
              repo_path = nil
              community_paths.each {|path| repo_path = path if path =~ /x86_64\/#{repo}/}
              downloader(repo_path, file, dest)

              # Grab from source if not on the download server
              downloader(source, file, dest) unless File.exist?("#{dest}/#{file}")

              FileUtils.copy "#{dest}/#{file}", "#{build_dir}/packages" if File.exist?("#{dest}/#{file}")

              abort(Simp::Metadata.critical("#{file} NOT FOUND")) unless File.exist?("#{dest}/#{file}")

              if progress
                progress.increment
              else
                print "#"
              end
            end

            # Copy noarch to x86_64
            x86_64_dir = "#{extract_dir}/SIMP/x86_64"
            FileUtils.makedirs "#{x86_64_dir}" unless File.directory?(x86_64_dir)
            rpms = Dir.glob(File.join("#{extract_dir}/SIMP/noarch", "**", "*rpm"))
            rpms.each { |rpm| FileUtils.cp rpm, x86_64_dir }

            # Purge package folders
            stage_header("Pruning unneeded packages")
            package_purge("#{extract_dir}/Packages")

            # Createrepo
            dirs = [
                #"#{extract_dir}/SIMP/noarch",
                "#{extract_dir}/SIMP/x86_64",
                #"#{extract_dir}/Packages"
            ]
            dirs.each { |dir| Dir.chdir(dir) { `createrepo .` } }

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
            makerepo(extract_dir) if iso == isos.last

            # Create ISO
            stage_header("Creating ISO #{iso_name}")
            Dir.chdir(iso_dir) { %x(#{iso_build_command}) }
            stage_header("Finished building ISO #{iso_name}")
          end

          # Move necessary files to final directory
          FileUtils.remove_dir "#{extract_dir}"
          FileUtils.move Dir.glob(File.join(iso_dir, '*.iso')), "#{currentdir}/#{platform}"
          preserve ? FileUtils.move(build_dir, "#{currentdir}/#{platform}") : FileUtils.remove_dir("#{build_dir}")
        end
        stage_header("Finished Build Process")
      end

      def build(build_type)
        case build_type
        when 'tarball'
          overlay_tarball_build
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
