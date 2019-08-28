module Simp
  module Metadata
    # Basic variables and methods for Build Class
    class RpmBuild
      include Enumerable
      attr_accessor :engine
      attr_accessor :release_version

      def initialize(engine, version, options)
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

      def excludes
        @excludes
      end

      def component(name)
        engine.releases[release_version].sources[name]
      end

      def deprecation_check
        if component.deprecated?
          abort(Simp::Metadata.critical("Component #{name} is deprecated. Can't build. Try downloading.")[0])
        end
      end

      def exist_check(dest)
        file = component.rpm_name
        if File.exist?("#{dest}/#{file}")
          abort(Simp::Metadata.critical("#{file} already exists at #{dest}. Please delete this to rebuild.")[0])
        end
      end

      def scripts

      end
=begin
def before_install_script
  script = <<-HEREDOC
# (default scriptlet for SIMP 6.x)
# when $1 = 1, this is an install
# when $1 = 2, this is an upgrade
preinstall scriptlet (using /bin/sh):
mkdir -p %{_localstatedir}/lib/rpm-state/simp-adapter   # Create rpm-state folder for repo
touch %{_localstatedir}/lib/rpm-state/simp-adapter/rpm_status$1.auditd # Create status $1 file

if [ -x /usr/local/sbin/simp_rpm_helper ] ; then
  /usr/local/sbin/simp_rpm_helper --rpm_dir=/usr/share/simp/modules/auditd --rpm_section='pre' --rpm_status=$1
fi
  HEREDOC
      end

preuninstall scriptlet (using /bin/sh):
if [ -x /usr/local/sbin/simp_rpm_helper ] ; then
  /usr/local/sbin/simp_rpm_helper --rpm_dir=/usr/share/simp/modules/auditd --rpm_section='preun' --rpm_status=$1
fi

postuninstall scriptlet (using /bin/sh):
if [ -x /usr/local/sbin/simp_rpm_helper ] ; then
  /usr/local/sbin/simp_rpm_helper --rpm_dir=/usr/share/simp/modules/auditd --rpm_section='postun' --rpm_status=$1
fi
posttrans scriptlet (using /bin/sh):
if [ -e %{_localstatedir}/lib/rpm-state/simp-adapter/rpm_status1.auditd ] ; then
  rm %{_localstatedir}/lib/rpm-state/simp-adapter/rpm_status1.auditd
  if [ -x /usr/local/sbin/simp_rpm_helper ] ; then
    /usr/local/sbin/simp_rpm_helper --rpm_dir=/usr/share/simp/modules/auditd --rpm_section='posttrans' --rpm_status=1
  fi
elsif [ -e %{_localstatedir}/lib/rpm-state/simp-adapter/rpm_status2.auditd ] ; then
  rm %{_localstatedir}/lib/rpm-state/simp-adapter/rpm_status2.auditd
  if [ -x /usr/local/sbin/simp_rpm_helper ] ; then
    /usr/local/sbin/simp_rpm_helper --rpm_dir=/usr/share/simp/modules/auditd --rpm_section='posttrans' --rpm_status=2
  fi
fi
HEREDOC
                    end
=end
      def requires; end

      def obsoletes; end

      def fpm_command(metadata)
        meta_url = metadata['source'] =~ /github/ ? metadata['source'] : 'https://www.simp-project.com'
        heredoc = <<~HEREDOC
          fpm
          -s dir
          -t rpm
          --name '#{component.rpm_basename}'
          --rpm-summary '#{metadata['name'].split('-')[1].capitalize} Puppet Module'
          --description '#{metadata['summary']}'
          --maintainer 'info@onyxpoint.com'
          --category Applications/System
          --url "#{meta_url}"
          --license '#{metadata['license']}'
          --package '#{currentdir}/#{rpm_name}'
          --version '#{metadata['version']}'
          --iteration '#{component.revision}'
          --architecture '#{component.target}'
          --vendor "#{metadata['author']}"
          --before-install #{before_install_script}
          --after-install #{after_install_script}
          --before-remove #{before_remove_script}
          --after-remove #{after_remove_script}
          --pretrans #{pretrans_script}
          --posttrans #{posttrans_script}
          --log debug
          --verbose
          --prefix /usr/share/simp/modules
          -C #{dir}/usr/share/simp/modules
          --directories=/usr/share/simp/modules/#{component.module_name}
          --rpm-digest sha512 -d 'simp-adapter >= 0.1.1'
        HEREDOC

        command  = heredoc.tr("\n", ' ')
        command += requires if requires
        command += obsoletes if obsoletes
        command
      end

      def component_rpm_build(name, destination)
        component(name)
        currentdir = Dir.pwd
        destination = currentdir if destination.nil?

        deprecation_check
        exist_check(destination)

        # Create destination dir
        FileUtils.makedirs destination unless File.directory?(destination)

        # Create tmp dir and clone source
        dir = Dir.mktmpdir
        Dir.chdir(dir.to_s) { Simp::Metadata.run("git clone #{url} source > /dev/null") }
        Dir.chdir("#{dir}/source")
        Simp::Metadata.run("git checkout #{component.version}")

        # sanitize
        sanitize

        # Grab Requires and Obsoletes
        requires = ''
        obsoletes = ''
        metadata = nil
        spec_data = nil
        dependencies_file = YAML.load_file("#{project_dir}/dependencies.yaml")
        requires.push(dependencies_file[name][:requires]) if dependencies_file[name][:requires]
        obsoletes.push(dependencies_file[name][:obsoletes]) if dependencies_file[name][:obsoletes]

        if File.exist?('./metadata.json')
          build_file = 'metadata'
          metadata = JSON.parse(File.read('./metadata.json'))
        elsif File.exist?(Dir.glob(File.join('build', '*.spec')))
          build_file = 'spec'
          spec_data = Dir.glob(File.join('build', '*.spec'))[0]
        else
          abort(Simp::Metadata.critical("Failed to find metadata or spec file to build RPM for #{name}")[0])
        end

        case build_file
        when 'metadata'
          deps = metadata['dependencies']
          deps.each do |hash|
            name = hash.values[0]
            version = if hash.values[1].include?(x)
                        split = hash.values[1].split('.')
                        if split.count == 3
                          ">= #{split[0]}.#{split[1]}.0 < #{split[0].to_i + 1}.0.0"
                        else
                          ">= #{split[0]}.0.0 < #{split[0].to_i + 1}.0.0"
                        end
                      else
                        hash.values[1]
                      end

            case version
            when /^\s*(\d+\.\d+\.\d+)\s*$/
              requires << "Requires: #{name} = #{Regexp.last_match(1)}"
            when /^\s*(?:(?:([<>]=?)\s*(\d+\.\d+\.\d+))\s*(?:(<=?)\s*(\d+\.\d+\.\d+))?)\s*$/
              requires << " -d '#{name} #{Regexp.last_match(1)} #{Regexp.last_match(2)}'"
              requires << " -d '#{name} #{Regexp.last_match(3)} #{Regexp.last_match(4)}'" if Regexp.last_match(3)
            else
              Simp::Metadata.warning("Can't process Deps for RPM #{name}")
            end
          end
        when 'spec'
          Simp::Metadata.warning("No current build method for Spec. #{spec_data}")
        else
          abort(Simp::Metadata.critical("Unrecognized repo format")[0])
        end

        # Make build dirs
        content_dir = "#{dir}/usr/share/simp/modules/#{component.module_name}"
        FileUtils.makedirs content_dir

        # Create tarball and extract to tmp/usr/share/simp/#{module_name}
        tar_command = "tar -cf - --exclude=./#{excludes.join(' --exclude=./')} ."
        errorcode = Simp::Metadata.run("#{tar_command} | tar -xvpf - -C #{content_dir}")
        abort(Simp::Metadata.critical("Failed to create #{component.name} repo tarball")) unless errorcode == 0
        # Set RPM build options
        # metadata = JSON.parse File.read('metadata.json')

        # Create RPM
        # Dir.chdir(dir.to_s)
        errorcode = Simp::Metadata.run("#{fpm_command(metadata)} 2> /dev/null")
        abort(Simp::Metadata.critical("Failed to create RPM for #{component.module_name}")[0]) unless errorcode == 0
        puts "RPM #{component.rpm_name} built successfully" if File.exist?("#{currentdir}/#{component.rpm_name}")

        # Cleanup
        Dir.chdir(dir.to_s)
        FileUtils.move "#{currentdir}/#{component.rpm_name}", destination unless currentdir == destination
        FileUtils.remove_entry dir
      end
    end
  end
end
