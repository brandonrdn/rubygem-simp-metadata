require 'simp/media'
require 'optparse'
module Simp
  module Media
    class Command
      def run(argv)
        options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: simp-media [options]"

          opts.on("-v", "--version [version]", "version to install") do |opt|
            options["version"] = opt
          end
          opts.on("-i", "--input [file]", "input filename") do |opt|
            options["input"] = opt
          end
          opts.on("-t", "--input-type [type]", "input install type", "valid types:", "  - internet", "  - local", "  - tar", "  - iso") do |opt|
            options["input_type"] = opt
          end
          opts.on("-o", "--output [file]", "output filename, path, or url (if control_repo type is specified)") do |opt|
            options["output"] = opt
          end
          opts.on("-T", "--output-type [type]", "output install type", "valid types:", "  - control_repo", "  - local", "  - tar", "  - iso") do |opt|
            options["output_type"] = opt
          end
          opts.on("-e", "--edition [edition_name]", "SIMP Edition", "valid editions:", "  - community", "  - enterprise") do |opt|
            options["edition"] = opt
          end
          opts.on("-f", "--flavor [flavor_name]", "SIMP flavor", "valid flavors:", "  - default") do |opt|
            options["destination_branch"] = opt
          end
          opts.on("-c", "--channel [channel_name]", "Distribution Channel") do |opt|
            options["channel"] = opt
          end
          opts.on("-l", "--license [license]", "path to license file") do |opt|
            options["license"] = opt
          end
          opts.on("-s", "--sign", "sign output (if applicable)") do |opt|
            options["sign"] = opt
          end
          opts.on("-S", "--signing-key [keyid]", "GPG ID of signing key") do |opt|
            options["signing_key"] = opt
          end
          opts.on("-D", "--local-directory [directory]", "Local directory to add to SIMP") do |opt|
            options["local_directory"] = opt
          end
          opts.on("-u", "--url [url]", "URL of git hosting server to use (control-repo output only)") do |opt|
            options["embed"] = opt
          end
          opts.on("-E", "--embed", "embed puppet modules (control-repo output only)") do |opt|
            options["embed"] = opt
          end
          opts.on("-b", "--branch [branch_name]", "branch to use (control-repo output only)") do |opt|
            options["branch"] = opt
          end
          opts.on("-B", "--destination_branch [branch_name]", "destination branch to use (control-repo output only)") do |opt|
            options["destination_branch"] = opt
          end
          opts.on("-d", "--debug [level]", "debug logging level: critical, error, warning, info, debug1, debug2") do |opt|
            $simp_metadata_debug_level = opt
          end
        end.parse!(argv)
        media = Simp::Media::Engine.new(options)
        media.run
      end
    end
  end
end

