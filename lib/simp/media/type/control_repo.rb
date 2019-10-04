module Simp
  module Media
    module Type
      # Media Control Repo Class
      class ControlRepo < Simp::Media::Type::Base
        attr_accessor :options

        def initialize(options, engine)
          super(options, engine)
          @cleanup = []
          raise 'output must be specified for control-repo output' if options[:output].nil?

          @temp_cache_dir = Dir.mktmpdir('cachedir')
          @repo_path = "#{@temp_cache_dir}/control-repo"
          FileUtils.mkdir_p(@repo_path)
          @cleanup << @temp_cache_dir
          output_clone

          Dir.chdir(@repo_path) do
            commands = ["git checkout #{options[:branch]}", "git checkout -b #{options[:branch]}"]
            commands.each_with_index do |command, index|
              exit_code = run(command)
              break if exit_code.success?
              raise "error, unable to checkout #{options[:branch]} in git repo #{uri}" if index == commands.size - 1
            end

            @branch = options[:branch]
            unless options[:destination_branch].nil?
              @branch = options[:destination_branch]
              exit_code = run("git checkout -b #{options[:destination_branch]}")
              unless exit_code.success?
                raise "error, unable to create branch #{options[:destination_branch]} in git repo #{uri}"
              end
            end
            run('rm -rf SIMP/modules')
            run('rm -rf SIMP/assets')
          end
        end

        def output_clone
          exit_code = run("git clone #{options[:output]} #{@repo_path}")
          unless exit_code.success?
            uri = URI(options[:output])
            if uri.scheme == 'file'
              FileUtils.mkdir_p(uri.path)
              Dir.chdir(uri.path) do |path|
                command = 'git init'
                command << " --bare" if path =~ /.*\.git$/
                run(command)
                run("git clone #{options[:output]} #{@repo_path}")
              end
            else
              raise 'output is not a valid control-repo'
            end
          end
        end

        def add_component(component, fetch_return_value)
          @path = fetch_return_value['path']
          # TODO: Add necessary references to generate the puppetfile during finalize
          raise 'not yet implemented' unless options[:embed]

          # TODO: Copy components to control-repo if embed == true
          case component.component_type
            # when 'documentation'
            # Need to add documentation info
          when 'simp-metadata'
            simp_metadata_git(component)
          when 'puppet-module'
            puppet_module_git(component)
          else
            subdirectory = "SIMP/assets/#{component.name}"
            if component.output_type == :file
              FileUtils.mkdir_p("#{@repo_path}/#{subdirectory}")
              FileUtils.cp(path, "#{@repo_path}/#{subdirectory}/#{component.output_filename}")
            end
          end
        end

        def simp_metadata_git(component)
          subdirectory = 'SIMP/metadata'
          output_path = "#{@repo_path}/#{subdirectory}/#{component.name}"
          FileUtils.mkdir_p(output_path)
          command = if Dir.exist?("#{@path}/.git")
                      "cd #{@path} && git --work-tree=\"#{output_path}\" checkout #{component.version} ."
                    else
                      "cd #{@path} && tar -cf - . | tar -xvpf - -C \"#{output_path}\""
                    end
          exit_code = run(command)
          unless exit_code.success?
            error "unable to copy #{component.name} to #{output_path}: error code #{exit_code.exitstatus}"
          end
        end

        def puppet_module_git(component)
          subdirectory = 'SIMP/modules'
          output_path = "#{@repo_path}/#{subdirectory}/#{component.module_name}"
          debug2("Copying #{component.module_name} to #{output_path}")
          FileUtils.mkdir_p(output_path)
          command = "cd #{@path} && git --work-tree=\"#{output_path}\" checkout #{component.version} ."
          exit_code = run(command)
          unless exit_code.success?
            Simp::Metadata::Debug.critical("unable to copy #{component.module_name} to #{output_path}")
            Simp::Metadata::Debug.abort("error code #{exit_code.exitstatus}")
          end
        end

        def finalize(_manifest)
          # TODO: Generate Puppetfile (if options["embed"] == false)
          #     Otherwise copy to control-repo
          #     ToDo: Munge Puppetfile
          environment_conf = "#{@repo_path}/environment.conf"
          hiera_yaml = "#{@repo_path}/hiera.yaml"
          # TODO: Munge hiera.yaml
          munge_hiera_yaml(hiera_yaml)
          munge_environment_conf(environment_conf) if options[:embed]
          run("cd #{@repo_path} && git add -A")
          run("cd #{@repo_path} && git commit -m \"simp-install: upgrade to #{options[:version]}\"")
          run("cd #{@repo_path} && git push origin #{@branch}")
        end

        def munge_environment_conf(environment_conf)
          # Munge environment.conf to add SIMP/modules to module_path
          if File.exist?(environment_conf)
            data = grab_data
            File.open(environment_conf, 'w') { |f| f.write(data.join("\n")) }
          else
            File.open(environment_conf, 'w') { |f| f.write("modulepath = modules:SIMP/modules:$basemodulepath\n") }
          end
        end

        def grab_data
          data = File.read(environment_conf).split("\n")
          data.each_with_index do |line, file_line|
            next unless /^modulepath = (?<capture>.*)$/ =~ line

            paths = capture.split(':')
            found = false
            module_index = nil
            paths.each_with_index do |path, index|
              module_index = index if path =~ /modules/
              found = true if path =~ /simp\/modules/
            end
            next if found

            new_array = []
            paths.each do |path, index|
              new_array << path
              new_array << 'SIMP/modules' if index == module_index
            end
            data[file_line] = "modulepath = #{new_array.join(':')}"
          end
          data
        end

        def raw_yaml
          output = <<~HEREDOC
            ---
            version: 5
            defaults:
              datadir: "data"
              data_hash: "yaml_data"
            hierarchy:
              - name: 'SIMP Defaults'
                paths:
                  - 'hosts/%{trusted.certname}'
                  - 'domains/%{facts.domain}'
                  - '%{facts.os.family}'
                  - '%{facts.os.name}/%{facts.os.release.full}'
                  - '%{facts.os.name}/%{facts.os.release.major}'
                  - '%{facts.os.name}'
                  - 'hostgroups/%{::hostgroup}'
                  - 'hosttypes/%{::hosttype}'
                  - 'users'
                  - 'groups'
                  - 'type/%{::nodetype}/common.yaml'
                  - 'default'
                  - 'simp_config_settings'
              - name: 'SIMP Compliance Engine'
                lookup_key: 'compliance_markup::enforcement'
          HEREDOC
          output
        end

        def munge_hiera_yaml(hiera_yaml)
          data = {}
          data = File.exist?(hiera_yaml) ? YAML.load_file(hiera_yaml) : YAML.safe_load(raw_yaml)
          version = data['version']
          case version
          when 4, 3, nil
            # TODO: Add version 3 and 4 hiera.yaml support
            raise "currently only version 5 hiera.yaml's are supported"
          when 5
            found = false
            hierarchy = data['hierarchy']
            hierarchy.each { |hash| found = true if hash['lookup_key'] == 'compliance_markup::enforcement' }
            unless found
              hash = { 'name' => 'SIMP Compliance Engine', 'lookup_key' => 'compliance_markup::enforcement' }
              data['hierarchy'] << hash
            end
          end
          File.open(hiera_yaml, 'w') { |f| f.write(data.to_yaml) }
        end

        def cleanup
          @cleanup.each do |path|
            FileUtils.rmtree(path)
          end
        end
      end
    end
  end
end
