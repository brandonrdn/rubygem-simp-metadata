require 'fileutils'
module Simp
  module Media
    module Type
      # Media Tar Class
      class Tar < Simp::Media::Type::Base
        def initialize(options, engine)
          @cleanup = []

          @temp_cache_dir = Dir.mktmpdir('cachedir')
          @tempdir = @temp_cache_dir + '/' + File.basename(options[:output], '.*')
          @cleanup << @temp_cache_dir
          super(options, engine)
        end

        def grab_subdirectory(component)
          case component.component_type
          when 'documentation'
            'SIMP/docs'
          when 'simp-metadata'
            'SIMP/metadata'
          when 'puppet-module'
            'SIMP/modules'
          else
            "SIMP/assets/#{component.name}"
          end
        end

        def add_component(component, fetch_return_value)
          subdirectory = grab_subdirectory(component)
          path = fetch_return_value[:path]
          case component.output_type
          when :directory
            if Dir.exist?(path)
              unless Dir.exist?(@tempdir + "/#{subdirectory}/#{component.name}")
                FileUtils.mkdir_p(@tempdir + "/#{subdirectory}/#{component.name}")
              end
              FileUtils.cp_r(path + '/.', @tempdir + "/#{subdirectory}/#{component.output_filename}")
            else
              raise "Unable to find component #{component.name} in input source: path=#{path}"
            end
          when :file
            if File.exist?(path)
              FileUtils.mkdir_p(@tempdir + "/#{subdirectory}")
              FileUtils.cp_r(path, @tempdir + "/#{subdirectory}/#{component.output_filename}")
            else
              raise "Unable to find component #{component.name} in input source: path=#{path}"
            end
          end
        end

        def finalize(_manifest)
          if @options.key?('local_directory')
            if Dir.exist?(@options[:local_directory])
              FileUtils.cp_r(Dir.glob(@options[:local_directory] + '/*'), @tempdir)
            end
          end
          Dir.chdir(@temp_cache_dir) do
            `tar -cf - * | gzip -9nc >#{@options[:output]}`
          end
        end

        # Needs to be finished/fixed
        def output(_options, _directory, version, metadata, _output)
          metadata.releases[version].sources.each do |_component|
          end
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
