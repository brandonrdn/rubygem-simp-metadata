require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Help Class to dynamically grab commands and descriptions
      class Help < Simp::Metadata::Commands::Base
        def description
          'Display commands for simp-metadata'
        end

        def subcommands
          output = Simp::Metadata::Commands.constants.select { |c| Simp::Metadata::Commands.const_get(c).is_a? Class }
          output.delete_if { |sub| sub.to_s == 'Base' }
          output.sort_by { |name, _data| name }
        end

        def get_command_description(command)
          mod = Module.const_get("Simp::Metadata::Commands::#{command}").new
          mod.description
        end

        def command_input(command)
          # Grabs CamelCase name and splits it to user command (ex: SetWrite to set-write)
          command.to_s.scan(/[A-Z][a-z]+/).join('-').downcase
        end

        def run(_argv)
          help_hash = {}
          subcommands.each { |sub| help_hash[command_input(sub)] = get_command_description(sub) }

          # Return output
          puts 'Usage: simp-metadata [command] [options]'
          help_hash.each do |subcommand, description|
            output_string = "#{subcommand.to_s.downcase.ljust(38).rjust(42)}#{description}"
            puts output_string
          end
        end
      end
    end
  end
end
