require 'optparse'
require_relative '../commands'

module Simp
  module Metadata
    module Commands
      # Class to run multiple scripts at once using a file
      class Script < Simp::Metadata::Commands::Base
        attr_accessor :argv, :engine, :root

        def description
          'Execute a script containing multiple commands'
        end

        def run(argv, engine = nil)
          @argv = argv
          @engine = engine
          options = defaults(argv) do |opts, _options|
            opts.banner = 'Usage: simp-metadata script [options] <filename>'
            opts.banner << "  #{description}"
          end

          Simp::Metadata::Commands::Save.command_queue(Queue.new)

          @engine, @root = get_engine(engine, options)
          if argv[0].nil?
            Simp::Metadata::Debug.critical('filename must be specified')
            exit 3
          end
          data = File.read(argv[0])
          lines = data.split("\n")
          lines.each do |line|
            temp_argv = line.split(' ')
            next if temp_argv.empty?
            next if temp_argv[0] =~ /^#/

            Simp::Metadata::Save.command_queue(line)
            command = Module.const_get("Simp::Metadata::Commands::#{temp_argv[0].tr('-', '_').capitalize}").new
            temp_argv.shift
            command.run(temp_argv, engine)
          end
        end
      end
    end
  end
end
