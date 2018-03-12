require 'fileutils'
module Simp
  module Media
    module Type
      class Tar < Simp::Media::Type::Base

        def initialize(options, engine)
          @cleanup = []

          @origtempdir = Dir.mktmpdir("cachedir")
          @tempdir = @origtempdir + "/" + File.basename(options["output"], ".*")
          @cleanup << @origtempdir
          super(options, engine)
        end

        def add_component(component, fetch_return_value)
          case component.component_type
            when "documentation"
              subdirectory = "SIMP/docs"
            when "simp-metadata"
              subdirectory = "SIMP/metadata"
            when "puppet-module"
              subdirectory = "SIMP/modules"
            else
              subdirectory = "SIMP/assets/#{component.name}"
          end
          case component.output_type
            when :directory
              if (Dir.exists?(fetch_return_value["path"]))
                unless (Dir.exists?(@tempdir + "/#{subdirectory}/#{component.name}"))
                  FileUtils.mkdir_p(@tempdir + "/#{subdirectory}/#{component.name}")
                end
                FileUtils.cp_r(fetch_return_value["path"] + "/.", @tempdir + "/#{subdirectory}/#{component.output_filename}")
              else
                raise "Unable to find component #{component.name} in input source: path=#{fetch_return_value["path"]}"
              end
            when :file
              if (File.exists?(fetch_return_value["path"]))
                FileUtils.mkdir_p(@tempdir + "/#{subdirectory}")
                FileUtils.cp_r(fetch_return_value["path"], @tempdir + "/#{subdirectory}/#{component.output_filename}")
              else
                raise "Unable to find component #{component.name} in input source: path=#{fetch_return_value["path"]}"
              end
          end

        end

        def finalize(manifest)
          if @options.key?("local_directory")
            if Dir.exists?(@options["local_directory"])
              FileUtils.cp_r(Dir.glob(@options["local_directory"] + "/*"), @tempdir)
            end
          end
          Dir.chdir(@origtempdir) do
            `tar -cf - * | gzip -9nc >#{@options["output"]}`
          end
        end

        def output(options, directory, version, metadata, output)
          metadata.releases[version].components.each do |component|
          end
        end
        def cleanup()
          @cleanup.each do |path|
            FileUtils.rmtree(path)
          end
        end
      end
    end
  end
end
