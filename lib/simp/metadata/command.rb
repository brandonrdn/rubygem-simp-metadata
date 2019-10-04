require 'simp/metadata/commands'
require 'simp/metadata'

module Simp
  module Metadata
    # Determine command and call that Class
    class Command
      def run(argv)
        begin
          input = argv[0]
          argv.shift
          command = %w[-h --help help].include?(input) ? 'help' : input
          command_name = command.split('-').map(&:capitalize).join('')
          mod = Module.const_get("Simp::Metadata::Commands::#{command_name}").new
        rescue StandardError => e
          Simp::Metadata::Debug.backtrace(e.backtrace)
          Simp::Metadata::Debug.critical(e.message)
          abort_message = input.nil? ? 'No command given' : "Unable to find command: #{command}"
          Simp::Metadata::Debug.abort(abort_message)
        end
        mod.run(argv)
      end
    end
  end
end
