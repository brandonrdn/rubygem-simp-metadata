require 'simp/media'
require 'optparse'
module Simp
  module Media
    # MediaCommand Options Class
    class Command
      def run(argv)
        options = {}
        OptionParser.new do |opts|
          # rubocop:disable Metrics/LineLength
          opts.banner = 'Usage: simp-media [options]'
          opts.on('-v', '--version [version]', 'version to install') { |opt| options[:version] = opt }
          opts.on('-i', '--input [file]', 'input filename') { |opt| options[:input] = opt }
          opts.on('-t', '--input-type [type]', 'input install type', 'valid types:', '  - internet', '  - local', '  - tar', '  - iso') { |opt| options[:input_type] = opt }
          opts.on('-o', '--output [file]', 'output filename, path, or url (if control_repo type is specified)') { |opt| options[:output] = opt }
          opts.on('-T', '--output-type [type]', 'output install type', 'valid types:', '  - control_repo', '  - local', '  - tar', '  - iso') { |opt| options[:output_type] = opt }
          opts.on('-e', '--edition [edition_name]', 'SIMP Edition(community or enterprise)') { |opt| options[:edition] = opt }
          opts.on('-f', '--flavor [flavor_name]', 'SIMP flavor', 'valid flavors:', '  - default') { |opt| options[:destination_branch] = opt }
          opts.on('-c', '--channel [channel_name]', 'Distribution Channel') { |opt| options[:channel] = opt }
          opts.on('-l', '--license [license]', 'path to license file') { |opt| options[:license] = opt }
          opts.on('-s', '--sign', 'sign output (if applicable)') { |opt| options[:sign] = opt }
          opts.on('-S', '--signing-key [key id]', 'GPG ID of signing key') { |opt| options[:signing_key] = opt }
          opts.on('-D', '--local-directory [directory]', 'Local directory to add to SIMP') { |opt| options[:local_directory] = opt }
          opts.on('-u', '--url [url]', 'URL of git hosting server to use (control-repo output only)') { |opt| options[:embed] = opt }
          opts.on('-E', '--embed', 'embed puppet modules (control-repo output only)') { |opt| options[:embed] = opt }
          opts.on('-b', '--branch [branch_name]', 'branch to use (control-repo output only)') { |opt| options[:branch] = opt }
          opts.on('-B', '--destination_branch [branch_name]', 'destination branch to use (control-repo output only)') { |opt| options[:destination_branch] = opt }
          opts.on('-d', '--debug [level]', 'debug logging level: critical, error, warning, info, debug1, debug2') { |opt| Simp::Metadata::Debug.debug_level(opt) }
          # rubocop:enable Metrics/LineLength
        end.parse!(argv)
        media = Simp::Media::Engine.new(options)
        media.run
      end
    end
  end
end
