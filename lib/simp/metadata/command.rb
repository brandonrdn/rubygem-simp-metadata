require 'simp/metadata/commands'
require 'simp/metadata'

module Simp
  module Metadata
    # Determine command and call that Class
    class Command
      def run(argv)
        input = argv[0]
        argv.shift
        command = %w[-h --help help].include?(input) ? 'help' : input
        command_name = command.split('-').map(&:capitalize).join('')
        begin
          mod = Module.const_get("Simp::Metadata::Commands::#{command_name}").new
        rescue StandardError => e
          Simp::Metadata.backtrace(e.backtrace)
          Simp::Metadata.critical(e.message)
          abort(Simp::Metadata.critical("Unable to find command: #{command}")[0])
        end
        mod.run(argv)
      end
    end
  end
end
