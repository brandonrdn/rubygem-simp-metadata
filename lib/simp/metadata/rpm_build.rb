module Simp
  module Metadata
    # Basic variables and methods for Build Class
    class RpmBuild < BuildHandler
      include Enumerable
      attr_accessor :engine, :release_version, :excludes

      def initialize(engine, version, name, options)
        @engine = engine
        @name = name
        @release_version = version
        @options = options
      end

      def sanitize
        excludes = %w[.git .gitignore]
        if File.exist?('./.simp.yml')
          config = YAML.load_file('.simp.yml')
          if config.key?('sanitize')
            sanitize = config['sanitize']
            @excludes = excludes + ['.simp.yml'] + sanitize['exclude'] if sanitize.key?('exclude')
            sanitize['scripts'].each { |command| `#{command}` } if sanitize.key?('scripts')
          end
        end
      end

      def component
        engine.releases[release_version].components[@name]
      end

      def deprecation_check
        if component.deprecated?
          abort(Simp::Metadata::Debug.critical("Component #{@name} is deprecated. Can't build. Try downloading.")[0])
        end
      end

      def exist_check(dest)
        file = component.rpm_name
        if File.exist?("#{dest}/#{file}")
          abort(Simp::Metadata::Debug.critical("#{file} already exists at #{dest}. Please delete this to rebuild.")[0])
        end
      end

      def fpm_command(metadata, content_dir, rpm_destination, requires, obsoletes)
        scripts_dir = "#{Simp::Metadata.main_project_dir}/scripts"
        meta_url = metadata['source'] =~ /github/ ? metadata['source'] : 'https://www.simp-project.com'
        heredoc = <<~HEREDOC
          fpm
          -s dir
          -t rpm
          --name '#{component.package_name}'
          --rpm-summary '#{metadata['name'].split('-')[1].capitalize} Puppet Module'
          --description '#{metadata['summary']}'
          --maintainer 'info@onyxpoint.com'
          --category Applications/System
          --url "#{meta_url}"
          --license '#{metadata['license']}'
          --package '#{rpm_destination}/#{component.rpm_name}'
          --version '#{metadata['version']}'
          --iteration '#{component.revision}'
          --architecture '#{component.target}'
          --vendor "#{metadata['author']}"
          --before-install #{scripts_dir}/before-install.sh
          --after-install #{scripts_dir}/after-install.sh
          --before-remove #{scripts_dir}/before-remove.sh
          --after-remove #{scripts_dir}/after-remove.sh
          --rpm-posttrans #{scripts_dir}/post-trans.sh
          --log debug
          --verbose
          --prefix /usr/share/simp/modules
          -C #{content_dir}
          --directories=/usr/share/simp/modules/#{component.module_name}
          --rpm-digest sha512
          -d 'simp-adapter >= 0.1.1'
        HEREDOC

        command  = heredoc.tr("\n", ' ')
        command += requires if requires
        command += obsoletes if obsoletes
        command
      end

      def metadata_grabber
        if File.exist?('./metadata.json')
          build_file = 'metadata'
          metadata = JSON.parse(File.read('./metadata.json'))
        elsif !Dir.glob(File.join('build', '*.spec')).empty?
          build_file = 'spec'
          metadata = Dir.glob(File.join('build', '*.spec'))[0]
        else
          abort(Simp::Metadata::Debug.critical("Failed to find metadata or spec file to build RPM for #{@name}")[0])
        end
        [build_file, metadata]
      end

      def dependency_version(hash)
        if hash.values[1].include?('x')
          split = hash.values[1].split('.')
          if split.count == 3
            ">= #{split[0]}.#{split[1]}.0 < #{split[0].to_i + 1}.0.0"
          else
            ">= #{split[0]}.0.0 < #{split[0].to_i + 1}.0.0"
          end
        else
          hash.values[1]
        end
      end

      def set_base_dependencies(requires_from_file, obsoletes_from_file)
        requires = ''
        obsoletes = ''
        requires_from_file.each { |name| requires << "-d '#{name}'" } if requires_from_file
        obsoletes_from_file.each { |name, ver| obsoletes >> "-replaces '#{name} <= #{ver}'" } if obsoletes_from_file
        [requires, obsoletes]
      end

      def dependency_grabber
        build_file, file_metadata = metadata_grabber
        dependencies_file = "#{project_dir.chomp('/')}/dependencies.yaml"
        content = YAML.load_file(dependencies_file)
        requires_from_file = content.dig(@name, :requires) ? content.dig(@name, :requires) : []
        obsoletes_from_file = content.dig(@name, :obsoletes) ? content.dig(@name, :obsoletes) : []
        requires, obsoletes = set_base_dependencies(requires_from_file, obsoletes_from_file)

        case build_file
        when 'metadata'
          deps = file_metadata['dependencies']
          deps.each do |hash|
            name = hash.values[0]
            version = dependency_version(hash)
            case version
            when /^\s*(\d+\.\d+\.\d+)\s*$/
              requires << "Requires: #{name} = #{Regexp.last_match(1)}"
            when /^\s*(?:(?:([<>]=?)\s*(\d+\.\d+\.\d+))\s*(?:(<=?)\s*(\d+\.\d+\.\d+))?)\s*$/
              requires << " -d '#{name} #{Regexp.last_match(1)} #{Regexp.last_match(2)}'"
              requires << " -d '#{name} #{Regexp.last_match(3)} #{Regexp.last_match(4)}'" if Regexp.last_match(3)
            else
              Simp::Metadata::Debug.warning("Can't process Deps for RPM #{name}")
            end
          end
        when 'spec'
          Simp::Metadata::Debug.warning("No current build method for Spec. #{file_metadata}")
        else
          abort(Simp::Metadata::Debug.critical("Unrecognized repo format")[0])
        end
        [requires, obsoletes, file_metadata]
      end

      def component_rpm_build(name, destination)
        @name = name
        currentdir = Dir.pwd
        rpm_destination = destination || currentdir
        deprecation_check
        exist_check(rpm_destination)

        # Create destination dir
        FileUtils.makedirs rpm_destination unless File.directory?(destination)

        # Create tmp dir and clone source
        dir = Dir.mktmpdir
        Dir.chdir(dir.to_s) { Simp::Metadata.run("git clone #{component.url} source > /dev/null") }
        Dir.chdir("#{dir}/source")
        Simp::Metadata.run("git checkout #{component.version}")

        # sanitize
        sanitize

        # Grab Requires and Obsoletes
        requires, obsoletes, file_metadata = dependency_grabber

        # Make build dirs
        content_dir = "#{dir}/content"
        module_name = component.module_name
        FileUtils.makedirs "#{content_dir}/#{module_name}"

        # Create tarball and extract dir/content/#{module_name}
        tar_command = if @excludes
                        "tar -cf - --exclude=./#{@excludes.join(' --exclude=./')} ."
                      else
                        "tar -cf - ."
                      end
        errorcode = Simp::Metadata.run("#{tar_command} | tar -xvpf - -C #{content_dir}/#{module_name}")
        abort(Simp::Metadata::Debug.critical("Failed to create #{component.name} repo tarball")) unless errorcode == 0
        # Set RPM build options
        # metadata = JSON.parse File.read('metadata.json')

        # Create RPM
        command = fpm_command(file_metadata, content_dir, rpm_destination, requires, obsoletes)
        errorcode = Simp::Metadata.run("#{command} 2> /dev/null")
        puts errorcode
        Simp::Metadata::Debug.abort("Failed to create RPM for #{component.module_name}") unless errorcode == 0
        puts "#{component.rpm_name} RPM build successful" if File.exist?("#{currentdir}/#{component.rpm_name}")

        # Cleanup
        Dir.chdir(currentdir)
        FileUtils.remove_entry dir
      end
    end
  end
end
