module Simp
  module Metadata
    # Basic variables and methods for Build Class
    class BuildHandler
      include Enumerable
      attr_accessor :engine
      attr_accessor :release_version

      def initialize(engine, version, options)
        @engine = engine
        @name = name
        @release_version = version
        @options = options
      end

      def options
        engine.options
      end

      def el_version
        options[:el_version]
      end

      def el_version_number
        el_version.split('el')[-1]
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

      def destination
        options[:destination] || Dir.pwd
      end

      def release
        options[:release]
      end

      def preserve
        options[:preserve] || nil
      end

      def build_version
        options[:build_os_version]
      end

      def os_version
        "el#{iso.split('-')[1].chr}"
      end

      def os_family
        iso.split('-')[0]
      end

      def build_dir
        currentdir
        @build_dir = options[:build_dir] || "#{currentdir}/build" if @build_dir.nil?
        @build_dir
      end

      def output_dirs
        output = []
        %w[isos rpms tarballs unsigned_rpms packages].each { |dir| output.push("#{build_dir}/#{dir}") }
        output
      end

      def rpm_cache
        if options[:rpm_cache]
          path = options[:rpm_cache]
          rpm_cache = path =~ /^\.\/.+$/ ? "#{currentdir}/#{path.split('./')[-1]}" : options[:rpm_cache]
        else
          rpm_cache = "#{currentdir}/rpms"
        end
        rpm_cache
      end

      def iso_cache
        if options[:iso_cache]
          path = options[:iso_cache]
          iso_cache = path =~ /^\.\/.+$/ ? "#{currentdir}/#{path.split('./')[-1]}" : options[:iso_cache]
        else
          iso_cache = "#{currentdir}/ISO"
        end
        iso_cache
      end

      def tar_cache
        if options[:tar_cache]
          path = options[:tar_cache]
          tar_cache = path =~ /^\.\/.+$/ ? "#{currentdir}/#{path.split('./')[-1]}" : options[:tar_cache]
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

      def base_community_path
        options[:upstream_build] ? '/data/community-download/simp' : 'https://download.simp-project.com/simp'
      end

      def base_enterprise_path
        options[:upstream_build] ? '/data/enterprise-download/simp' : 'https://enterprise-download.simp-project.com:443'
      end

      def components
        engine.components
      end

      def packages
        engine.packages
      end

      def community_paths
        release = options[:release]
        release_dirs = [release, release.split('-')[0]]
        # Start with General dirs
        output = [
            "#{base_community_path}/yum/simp6/el/#{el_version_number}/x86_64",
            "#{base_community_path}/yum/unstable/simp6/el/#{el_version_number}/x86_64/simp",
            "#{base_community_path}/yum/unstable/simp6/el/#{el_version_number}/x86_64/epel",
            "#{base_community_path}/yum/unstable/simp6/el/#{el_version_number}/x86_64/postgresql",
            "#{base_community_path}/yum/unstable/simp6/el/#{el_version_number}/x86_64/puppet"
        ]
        # Add releases and rolling dirs
        releases_base = "#{base_community_path}/yum/releases"
        rolling_base = "#{base_community_path}/yum/rolling"
        ['simp','postgresql','epel','puppet'].each do |repo|
          # Add releases and rolling repos
          release_dirs.each { |rel| output.push("#{releases_base}/#{rel}/el/#{el_version_number}/x86_64/#{repo}") }
          release_dirs.each { |rel| output.push("#{rolling_base}/#{rel}/el/#{el_version_number}/x86_64/#{repo}") }
          # Add legacy Release repos
          release_dirs.each { |rel| output.push("#{releases_base}/#{rel}/#{el_version.upcase}/core") }
          release_dirs.each { |rel| output.push("#{releases_base}/#{rel}/#{el_version.upcase}/dependencies") }
        end
        output
      end

      def build_assets_path
        "#{base_community_path}/ISO/build_assets"
      end

      def get_dvd_data(src, dest)
        heredoc = <<~HEREDOC
          wget
          -r -E -x -p -q -nH
          --level=0
          --ignore-length
          -erobots=off
          --no-parent
          --cut-dirs=9
          -R "DVD.html*"
          -R "index.html*"
          -P #{dest}
          -N #{src}
        HEREDOC
        command = heredoc.tr("\n", ' ')
        src =~ /https?/ ? `#{command}` : `cp -r #{src}/* #{dest}`
      end

      def iso_check
        if File.exist?("#{iso_dir}/#{iso_name}")
          puts "### SIMP ISO #{iso_name} already exists! Not building for existing ISO"
          exit 12
        end
      end

      def tarball_check
        build_tarball = true
        extract_dir = nil
        if options[:overlay_tarball] && File.exist?("#{tar_cache}/#{overlay_tarball_name}")
          extract_dir = tar_cache
          build_tarball = false
        end
        [build_tarball, extract_dir]
      end

      def rpm_copy(source, destination)
        FileUtils.makedirs destination.to_s unless File.directory?(destination)
        rpms = Dir.glob(File.join(source.to_s, "**", "*rpm"))
        rpms.each { |rpm| FileUtils.cp rpm, destination }
      end

      def build_preserve(dirs)
        dirs.each do |dir|
          path = dir.split("#{extract_dir}/")[-1]
          FileUtils.makedirs("#{build_rpm_dir}/#{path}")
          rpms = Dir.glob(File.join(dir, '*.rpm'))
          rpms.each { |rpm| FileUtils.copy rpm, "#{build_rpm_dir}/#{path}" }
        end
      end

      def create_tarball(source_dir, dest_dir, name)
        Simp::Metadata.run("tar -czvf #{dest_dir}/#{name} #{source_dir}")
      end

      def stage_header(text)
        length = text.length + 8
        puts '', "#" * length, "##  #{text}  ##", "#" * length, ''
      end

      def project_dir
        Simp::Metadata.main_project_dir
      end

      def simp_rpm
        "simp-#{@release_version}.#{el_version}.noarch.rpm"
      end

      def get_simp_rpm(dest)
        unless File.exist?("#{dest}/#{simp_rpm}")
          downloader(download_source(nil, simp_rpm), simp_rpm, dest)
          Simp::Metadata::Debug.abort("Failed to download #{simp_rpm}") unless File.exist("#{dest}/#{simp_rpm}")
        end
      end

      def simp_doc_rpm
        "simp-doc-#{@release_version}.noarch.rpm"
      end

      def get_simp_doc_rpm(dest)
        unless File.exist?("#{dest}/#{simp_doc_rpm}")
          downloader(download_source(nil, simp_doc_rpm), simp_doc_rpm, simp_doc_rpm)
          unless File.exist?("#{dest}/#{simp_doc_rpm}")
            abort(Simp::Metadata::Debug.critical("Failed to download #{simp_doc_rpm}")[0])
          end
        end
      end

      def downloader(src, file, dest = Dir.pwd)
        source = src || download_source
        return if File.exist?("#{destination}/#{file}")

        case source
        when /^https?:/
          file_check = `curl -sLI #{source}/#{file} | head -n 1 | awk '{print $2}'`.chomp
          `wget -q --show-progress -P #{destination} #{source}/#{file}` if file_check == '200'
        else
          FileUtils.cp "#{source}/#{file}", destination if File.exist?("#{source}/#{file}")
        end
      end
    end
  end
end
