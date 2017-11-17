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

    def self.debug1(message)
    end
  end
end
