module Simp
  module Media
    module Type
      class Control_repo < Simp::Media::Type::Base
        attr_accessor :options
        def initialize(options, engine)
          super(options, engine)
          @cleanup = []
          if options[:output].nil?
            raise 'output must be specified for control-repo output'
          end
          @temp_cache_dir = Dir.mktmpdir('cachedir')
          @repo_path = "#{@temp_cache_dir}/control-repo"
          FileUtils.mkdir_p(@repo_path)
          @cleanup << @temp_cache_dir
          exit_code = run("git clone #{options[:output]} #{@repo_path}")
          unless exit_code.success?
            uri = URI(options[:output])
            if uri.scheme == 'file'
              FileUtils.mkdir_p(uri.path)
              Dir.chdir(uri.path) do |path|
                if path =~ /.*\.git$/
                  run('git init --bare')
                else
                  run('git init')
                end

                run("git clone #{options[:output]} #{@repo_path}")
              end
            else
              raise 'output is not a valid control-repo'
            end
          end
          Dir.chdir(@repo_path) do
            exit_code = run("git checkout #{options[:branch]}")
            unless exit_code.success?
              exit_code = run("git checkout -b #{options[:branch]}")
              unless exit_code.success?
                raise "error, unable to checkout #{options[:branch]} in git repo #{uri}"
              end
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

        def add_component(component, fetch_return_value)
          if options[:embed]
            # ToDo: Copy components to control-repo if embed == true
            case component.component_type
            when 'documentation'
            when 'simp-metadata'
              subdirectory = 'SIMP/metadata'
              output_path = "#{@repo_path}/#{subdirectory}/#{component.name}"
              FileUtils.mkdir_p(output_path)
              if Dir.exist?("#{fetch_return_value['path']}/.git")
                exit_code = run("cd #{fetch_return_value['path']} && git --work-tree=\"#{output_path}\" checkout #{component.version} .")
              else
                exit_code = run("cd #{fetch_return_value['path']} && tar -cf - . | tar -xvpf - -C \"#{output_path}\"")
              end

              unless exit_code.success?
                error "unable to copy #{component.name} to #{output_path}: error code #{exit_code.exitstatus}"
              end
            when 'puppet-module'
              subdirectory = 'SIMP/modules'
              output_path = "#{@repo_path}/#{subdirectory}/#{component.module_name}"
              debug2("Copying #{component.module_name} to #{output_path}")
              FileUtils.mkdir_p(output_path)
              exit_code = run("cd #{fetch_return_value['path']} && git --work-tree=\"#{output_path}\" checkout #{component.version} .")
              unless exit_code.success?
                error "unable to copy #{component.module_name} to #{output_path}: error code #{exit_code.exitstatus}"
              end
            else
              subdirectory = "SIMP/assets/#{component.name}"
              case component.output_type
              when :file
                FileUtils.mkdir_p("#{@repo_path}/#{subdirectory}")
                FileUtils.cp(fetch_return_value['path'], "#{@repo_path}/#{subdirectory}/#{component.output_filename}")
              end
            end
          else
            # ToDo: Add necessary references to generate the puppetfile during finalize
            raise 'not yet implemented'
          end
        end

        def finalize(_manifest)
          # ToDo: Generate Puppetfile (if options["embed"] == false)
          #     Otherwise copy to control-repo
          #     ToDo: Munge Puppetfile
          environment_conf = "#{@repo_path}/environment.conf"
          hiera_yaml = "#{@repo_path}/hiera.yaml"
          # ToDo: Munge hiera.yaml
          munge_hiera_yaml(hiera_yaml)
          munge_environment_conf(environment_conf) if options[:embed]
          run("cd #{@repo_path} && git add -A")
          run("cd #{@repo_path} && git commit -m \"simp-install: upgrade to #{options[:version]}\"")
          run("cd #{@repo_path} && git push origin #{@branch}")
        end

        def munge_environment_conf(environment_conf)
          # Munge environment.conf to add SIMP/modules to module_path
          if File.exist?(environment_conf)
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
              File.open(environment_conf, 'w') { |f| f.write(data.join("\n")) }
            end
          else
            File.open(environment_conf, 'w') { |f| f.write("modulepath = modules:SIMP/modules:$basemodulepath\n") }
          end
        end

        def munge_hiera_yaml(hiera_yaml)
          data = {}
          if File.exist?(hiera_yaml)
            data = YAML.load(File.read(hiera_yaml))
            version = data['version']
            case version
            when 4
              # ToDo: Add version 4 hiera.yaml support
              raise "currently version 4 hiera.yaml's are not supported"
            when 5
              found = false
              data['hierarchy'].each_with_index do |hash|
                if hash['lookup_key'] == 'compliance_markup::enforcement'
                  found = true
                end
              end
              unless found
                hash = { 'name' => 'SIMP Compliance Engine', 'lookup_key' => 'compliance_markup::enforcement' }
                data['hierarchy'] << hash
              end
            when nil
              # ToDo: Add version 3 hiera.yaml support
              raise "currently version 3 hiera.yaml's are not supported"
            end
          else
            raw_yaml = <<-EOF
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
            EOF
            data = YAML.load(raw_yaml)
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
