# vim: set expandtab ts=2 sw=2:
require 'open3'
require 'simp/metadata/engine'

require 'simp/metadata/source'
require 'simp/metadata/bootstrap_source'

require 'simp/metadata/releases'
require 'simp/metadata/release'

require 'simp/metadata/components'
require 'simp/metadata/component'

require 'simp/metadata/locations'
require 'simp/metadata/location'

module Simp
  module Metadata
    def self.run(command)
      exitcode = nil
      Open3.popen3(command) do |stdin, stdout, stderr, thread|
        pid = thread.pid
        Simp::Metadata.debug1(stdout.read.chomp)
        Simp::Metadata.debug1(stderr.read.chomp)
        exitcode = thread.value
      end
      exitcode
    end
    def self.level?(level)
      setlevel = Simp::Metadata.convert_level($simp_metadata_debug_level)
      checklevel = Simp::Metadata.convert_level(level)
      if (checklevel <= setlevel)
        true
      else
        false
      end
    end
    def self.convert_level(level)
      case level
        when 'critical'
          0
        when 'error'
          1
        when 'warning'
          2
        when 'info'
          3
        when 'debug1'
          4
        when 'debug2'
          5
        else
          2
      end
    end
    def self.print_message(prefix, message)
      message.split("\n").each do |line|
        puts "#{prefix}: #{line}"
      end
    end
    def self.debug1(message)
      if Simp::Metadata.level?('debug1')
        Simp::Metadata.print_message("DEBUG1", message)
      end
    end
    def self.debug2(message)
      if Simp::Metadata.level?('debug2')
        Simp::Metadata.print_message("DEBUG2", message)
      end
    end
    def self.info(message)
      if Simp::Metadata.level?('info')
        Simp::Metadata.print_message("INFO", message)
      end
    end
    def self.warning(message)
      if Simp::Metadata.level?('warning')
        Simp::Metadata.print_message("WARN", message)
      end
    end
    def self.error(message)
      if Simp::Metadata.level?('error')
        Simp::Metadata.print_message("ERROR", message)
      end
    end
    def self.critical(message)
      if Simp::Metadata.level?('critical')
        Simp::Metadata.print_message("CRITICAL", message)
      end
    end
  end
end
