module Simp
  module Metadata
    class Component
      include Enumerable
      attr_accessor :engine
      attr_accessor :release_version

      def initialize(engine, name, version)
        @engine = engine
        @name = name
        @release_version = version
      end

      def to_s
        self.name
      end

      def name(type = "component")
        case type
        when "component"
          @name
        when "puppetfile"
          if (component_type == "rubygem")
            "rubygem-#{@name.gsub(/-/, '_')}"
          elsif (component_type == "puppet-module")
            @name.gsub(/pupmod-/, '')
          else
            @name
          end
        else
          abort(Simp::Metadata.critical("Expected type to be 'component' or 'puppetfile'")[0])
        end
      end

      def component_source()
        retval = engine.sources["bootstrap_metadata"]
        engine.sources.each do |name, source|
          if (source.components != nil)
            if (source.components.key?(self.name))
              retval = source
              break
            end
          end
        end
        return retval
      end

      def release_source()
        retval = engine.sources["bootstrap_metadata"]
        engine.sources.each do |name, source|
          if (source.releases.key?(release_version))
            if (source.releases[release_version].key?(self.name))
              retval = source
              break
            end
          else
            if (source.release(release_version).key?(self.name))
              retval = source
              break
            end
          end
        end
        return retval
      end

      #
      # Will be used to grab method based data in the future, rather
      # then calling get_from_release or get_from_component directly,
      #
      # For now, just use it in Simp::Metadata::Buildinfo
      def fetch_data(item)
        component = get_from_component
        release = get_from_release
        if (release.key?(item))
          release[item]
        else
          component[item]
        end
      end

      def get_from_component()
        return self.component_source.components[self.name]
      end

      def get_from_release()
        retval = {}
        if (self.release_source.releases.key?(release_version))
          if (self.release_source.releases[release_version].key?(self.name))
            retval = self.release_source.releases[release_version][self.name]
          end
        else
          if (self.release_source.release(release_version).key?(self.name))
            retval = self.release_source.release(release_version)[self.name]
          end
        end
        return retval
      end

      def type
        get_from_component["type"]
      end

      def extension
        if (self.real_extension == nil)
          case (self.component_type)
          when "simp-metadata"
            "tgz"
          when "logstash-filter"
            "gem"
          when "rubygem"
            "gem"
          when "grafana-plugin"
            "zip"
          when "puppet-module"
            "tgz"
          else
            ""
          end
        else
          self.real_extension
        end
      end

      def keys()
        ["component_type", "authoritative", "asset_name", "extension", "format", "module_name", "type", "url", "method", "extract", "branch", "tag", "ref", "version", "release_source", "component_source", "target", "revision"]
      end

      def [] (index)
        self.send index.to_sym
      end

      def each(&block)
        self.keys.each do |key|
          yield key, self[key]
        end
      end

      def real_extension
        get_from_component["extension"]
      end

      def real_asset_name
        case self.component_type
        when "puppet-module"
          get_from_component["module_name"]
        when "rubygem"
          get_from_component["gem_name"]
        else
          get_from_component["asset_name"]
        end
      end

      def module_name
        asset_name
      end

      def asset_name
        if (self.real_asset_name == nil)
          case self.component_type
          when "puppet-module"
            splitted = self.name.split("-")
            splitted[splitted.size - 1]
          else
            self.name
          end
        else
          self.real_asset_name
        end
      end


      def output_type
        if (self.compiled?)
          return :file
        else
          return :directory
        end
      end

      def output_filename
        if (self.compiled?)
          return "#{self.name}-#{self.version}.#{self.extension}"
        else
          return self.name
        end
      end

      def primary
        self.locations.primary
      end

      def url
        self.locations.primary.url
      end

      def method
        self.locations.primary.method
      end

      def extract
        self.locations.primary.extract
      end

      def locations
        # XXX: ToDo Allow manifest.yaml to override locations
        # XXX: ToDo Use primary_source and mirrors here if locations is empty
        Simp::Metadata::Locations.new({"locations" => get_from_component["locations"], "primary_source" => get_from_component["primary_source"], "mirrors" => get_from_component["mirrors"]}, self)
      end

      # XXX: ToDo Generate a filename, and output file type; ie, directory or file


      def format
        get_from_component["format"]
      end

      def component_type
        get_from_component["component-type"]
      end

      def authoritative?
        get_from_component["authoritative"]
      end

      def authoritative
        get_from_component["authoritative"]
      end

      def revision
        revision = get_from_component["revision"]
        if revision.nil?
          "0"
        else
          revision
        end
      end

      def revision=(value)
        release = self.release_source.releases[release_version]
        if (release != nil)
          if (release.key?(name))
            release[name]["revision"] = value
          else
            release[name] = {"revision" => value}
          end
        end
        self.release_source.dirty = true
      end

      def ref
        get_from_release["ref"]
      end

      def ref=(value)
        release = self.release_source.releases[release_version]
        if (release != nil)
          if (release.key?(name))
            release[name]["ref"] = value
          else
            release[name] = {"ref" => value}
          end
        end
        self.release_source.dirty = true
      end

      def branch
        get_from_release["branch"]
      end

      def branch=(value)
        release = self.release_source.releases[release_version]
        if (release != nil)
          if (release.key?(name))
            release[name]["branch"] = value
          else
            release[name] = {"branch" => value}
          end
        end
        self.release_source.dirty = true
      end

      def tag
        get_from_release["tag"]
      end

      def tag=(value)
        release = self.release_source.releases[release_version]
        if (release != nil)
          if (release.key?(name))
            release[name]["tag"] = value
          else
            release[name] = {"tag" => value}
          end
        end
        self.release_source.dirty = true
      end

      def version
        ver = ""
        ["version", "tag", "ref", "branch"].each do |item|
          if (get_from_release[item] != nil)
            ver = get_from_release[item]
            break
          end
        end
        return ver
      end

      def rpm_basename
        if component_type == 'puppet-module'
          if name.match(/pupmod-*/)
            "#{name}"
          else
            "pupmod-#{name}"
          end
        else
          "#{name}"
        end
      end

      def component_version
        if version.match(/^[v][0-9]/)
          version.split('v')[1]
        else
          version
        end
      end

      def rpm_version
        if (component_version.match(/^[0-9]+.[0-9]+.[0-9]+.[0-9]+/))
          component_version
        else
          "#{component_version}-#{revision}"
        end
      end


      def target
        target = get_from_release["target"]
        if target.nil?
          "noarch"
        else
          target
        end
      end

      def target=(value)
        release = self.release_source.releases[release_version]
        if (release != nil)
          if (release.key?(name))
            release[name]["target"] = value
          else
            release[name] = {"target" => value}
          end
        end
        self.release_source.dirty = true
      end

      def platform
        platform = engine.options["platform"]
        if platform.nil?
          "el7"
        else
          platform
        end
      end

      def rpm_name
        if self.component_type == 'puppet-module'
          "#{rpm_basename}-#{rpm_version}.#{target}.rpm"
        else
          "#{rpm_basename}-#{rpm_version}.#{platform}.#{target}.rpm"
        end
      end

      def compiled?
        if get_from_release.key?("compiled")
          get_from_release["compiled"]
        else
          false
        end
      end

      def binaryname
        "#{asset_name}-#{version}.#{extension}"
      end

      def view(attribute)
        comp = self
        view_hash = {}
        if attribute.nil?
          comp.each do |key, value|
            unless value.nil? or value == ""
              view_hash[key] = value.to_s
            end
          end
          location_hash = {}
          comp.locations.each do |location|
            location.each do |key, value|
              unless value.nil?
                location_hash.merge!(key => value.to_s)
              end
            end
          end
          buildinfo_hash = {}
          comp.buildinfo.each do |buildinfo|
            buildinfo.each do |key, value|
            end
          end
          view_hash['location'] = location_hash
        else
          view_hash[attribute] = comp[attribute].to_s
        end
        return view_hash
      end

      def diff(component, attribute)
        diff = {}

        if attribute.nil?
          current_hash = {}
          comp_hash = {}
          self.each do |attribute, value|
            current_hash.merge!(attribute => value)
          end
          component.each do |attribute, value|
            comp_hash.merge!(attribute => value)
          end
          unless current_hash == comp_hash
            current_hash.each do |attribute, value|
              diff[attribute] = {"original" => "#{current_hash[attribute]}",
                                 "changed" => "#{comp_hash[attribute]}"} if comp_hash[attribute] != value
            end
          end
          return diff
        else
          v1 = self["#{attribute}"]
          v2 = component["#{attribute}"]
          unless (v1 == v2)
            diff[attribute] = {"original" => "#{v1}", "changed" => "#{v2}"}
            return diff
          end
        end
      end

      def buildinfo(type = nil)
        if (type == nil)
          {}
        else
          Simp::Metadata::Buildinfo.new(self, type)
        end
      end

      def build(destination)
        currentdir = Dir.pwd
        destination = currentdir if destination.nil?
        abort(Simp::Metadata.critical("File #{rpm_name} already exists in #{destination}. Please delete this file and re-run the command if you wish to replace it.")[0]) if File.exist?("#{destination}/#{rpm_name}")

        #Create tmp dir and clone source
        Dir.mktmpdir do |dir|
          Dir.chdir(dir.to_s) do
            system("git clone #{url} source > /dev/null")
            Dir.chdir("source") do
              system("git checkout #{version}")

              # sanitize
              excludes = %w('.git' '.gitignore')
              if File.exist?("./.simp.yml")
                config = YAML.load_file(".simp.yml")
                if config.key?("sanitize")
                  sanitize = config["sanitize"]
                  excludes = excludes + [".simp.yml"] + sanitize["exclude"] if sanitize.key?("exclude")
                  if sanitize.key?("scripts")
                    sanitize["scripts"].each do |command|
                      puts `#{command}`
                    end
                  end
                end
              end

              # Make build dirs
              FileUtils.makedirs "#{dir}/usr/share/simp/modules/#{module_name}"

              # Create tarball and extract to tmp/usr/share/simp/#{module_name}
              errorcode = Simp::Metadata.run("tar -cf - --exclude=./#{excludes.join(' --exclude=./')} . | tar -xvpf - -C #{dir}/usr/share/simp/modules/#{module_name}")
              abort(Simp::Metadata.critical("Failed to create and extract tarball for #{name}")) unless errorcode == 0

              # Set RPM build options
              metadata = JSON.parse File.read('metadata.json')

              heredoc = <<-HEREDOC
-s dir
-t rpm
--name '#{rpm_basename}'
--rpm-summary '#{metadata["name"].split('-')[1].capitalize} Puppet Module'
--description '#{metadata["summary"]}'
--maintainer 'info@onyxpoint.com'
--category Applications/System
--prefix 'usr/share/simp/modules'
--url '#{metadata["source"]}'
--vendor "Onyx Point, Inc"
--license '#{metadata["license"]}'
--package '#{currentdir}/#{rpm_name}'
--version '#{metadata["version"]}'
--iteration '#{revision}'
--architecture '#{target}'
--verbose
-C #{dir}/usr/share/simp/modules
--rpm-digest sha512 -d 'simp-adapter'
--directories=/usr/share/simp/modules/#{module_name}
              HEREDOC

              options = heredoc.gsub("\n", ' ')

              # Create RPM
              Dir.chdir(dir.to_s) do
                errorcode = Simp::Metadata.run("fpm #{options} 2> /dev/null")
                abort(Simp::Metadata.critical("Failed to create RPM for #{module_name}")[0]) unless errorcode == 0
                puts "RPM #{rpm_name} built successfully" if File.exist?("#{currentdir}/#{rpm_name}")
              end
            end
          end
        end
        FileUtils.move "#{currentdir}/#{rpm_name}", destination
      end

      def download(destination, source)
        destination = Dir.pwd if destination.nil?
        rpm_name = self.rpm_name
        return if File.exist?("#{destination}/#{rpm_name}")
        el_version = platform.split('el')[1]
        if source.nil?
          sources = %W("https://download.simp-project.com/SIMP/yum/simp6/el/#{el_version}/x86_64", "https://download.simp-project.com/SIMP/yum/unstable/el/#{el_version}/x86_64")
        else
          sources = ["#{source}"]
        end
        sources.each do |source|
          if source =~ /^https?:/
            file_check = `curl -sLI #{source}/#{rpm_name} | head -n 1 | awk '{print $2}'`.chomp
            `wget -q #{source}/#{rpm_name}` if file_check == '200'
          elsif File.exist?("#{source}/#{rpm_name}")
            FileUtils.cp "#{source}/#{rpm_name}", destination
          end
          puts "Copied #{rpm_name} from #{source}" if File.exist?("#{destination}/#{rpm_name}")
          return if File.exist?("#{destination}/#{rpm_name}")
        end
        puts "Unable to fine #{rpm_name} from #{sources}"
      end

    end
  end
end
