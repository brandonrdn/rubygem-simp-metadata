require 'simp/install'
require 'simp/media'
require 'optparse'
module Simp
  module Install
    class Command
      def run(argv)
        options = {}
        OptionParser.new do |opts|
          opts.banner = 'Usage: simp-install [options]'

          opts.on('-v', '--version [version]', 'version to install') do |version|
            options[:version] = version
          end
          opts.on('-i', '--input [file]', 'input filename') do |input|
            options[:input] = input
          end
          opts.on('-t', '--input-type [type]', 'input install type', 'valid types:', '  - internet', '  - local', '  - tar', '  - iso') do |input_type|
            options[:input_type] = input_type
          end
          opts.on('-o', '--output [file]', 'output filename, path, or url (if control_repo type is specified)') do |file|
            options[:output] = file
          end
          opts.on('-T', '--output-type [type]', 'output install type', 'valid types:', '  - control_repo', '  - local', '  - tar', '  - iso') do |output_type|
            options[:output_type] = output_type
          end
          opts.on('-e', '--edition [edition_name]', 'SIMP Edition', 'valid editions:', '  - community', '  - enterprise') do |edition|
            options[:edition] = edition
          end
          opts.on('-f', '--flavor [flavor_name]', 'SIMP flavor', 'valid flavors:', '  - default') do |flavor|
            options[:destination_branch] = flavor
          end
          opts.on('-c', '--channel [channel_name]', 'Distribution Channel') do |channel|
            options[:channel] = channel
          end
          opts.on('-l', '--license [license]', 'path to license file') do |license|
            options[:license] = license
          end
          opts.on('-s', '--sign', 'sign output (if applicable)') do |sign|
            options[:sign] = sign
          end
          opts.on('-S', '--signing-key [keyid]', 'GPG ID of signing key') do |key|
            options[:signing_key] = key
          end
          opts.on('-d', '--local-directory [directory]', 'Local directory to add to SIMP') do |directory|
            options[:local_directory] = directory
          end
          opts.on('-u', '--url [url]', 'URL of git hosting server to use (control-repo output only)') do |url|
            options[:embed] = url
          end
          opts.on('-E', '--embed', 'embed puppet modules (control-repo output only)') do |embed|
            options[:embed] = embed
          end
          opts.on('-b', '--branch [branch_name]', 'branch to use (control-repo output only)') do |branch|
            options[:branch] = branch
          end
          opts.on('-B', '--destination_branch [branch_name]', 'destination branch to use (control-repo output only)') do |destination|
            options[:destination_branch] = destination
          end
          opts.on('-d', '--debug [level]', 'debug logging level: critical, error, warning, info, debug1, debug2') do |debug|
            $simp_metadata_debug_level = debug
          end
        end.parse!(argv)
        media = Simp::Media::Engine.new(options)
        media.run
      end
    end
  end
end
