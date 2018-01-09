require 'simp/metadata/commands'
require 'simp/metadata'

module Simp
  module Metadata
    class Command
      def run(argv)
        command = argv[0]
        argv.shift
        # XXX ToDo: Make this dynamic, just instantiate a class named the subcommand
        if (command != "")
          if (command == "-h" || command == "help")
            self.help()
          else
            unless (command =~ /^#/)
              begin
                cmd = Module.const_get("Simp::Metadata::Commands::#{command.gsub("-", "_").capitalize}").new()

              rescue
                Simp::Metadata.critical("Unable to find command: #{command}")
                self.help
                exit 4
              end
              cmd.run(argv)
            end
          end
        else
          self.help()
        end
      end

      def help()
        puts "Usage: simp-metadata [command] [options]"
        # XXX: ToDo: make this dynamic...
        subcommands = [
            [
                "clone",
                "Clones one simp release into another",
            ],
            [
                "save",
                "Saves metadata changes",
            ],
            [
                "set-write",
                "Sets which metadata repo to write to if there are multiple",
            ],
            [
                "script",
                "Execute a script containing multiple commands",
            ]
        ]
        subcommands.each do |components|
          output_string = "#{(components[0].ljust(38)).rjust(42)}#{components[1]}"
          puts output_string
        end
      end
    end
  end
end
