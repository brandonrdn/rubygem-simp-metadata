require 'simp/metadata/components'
module Simp
  module Metadata
    class Release
      attr_accessor :engine
      attr_accessor :version

      def initialize(engine, version)
        @engine = engine
        @version = version
      end

      def components(type = nil)
        Simp::Metadata::Components.new(engine, version, type)
      end

      def to_s()
        self.components.to_s
      end
    end
  end
end

