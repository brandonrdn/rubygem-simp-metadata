require 'uri'

module Simp
  module Metadata
    class FakeURI
      attr_accessor :scheme
      attr_accessor :host
      attr_accessor :port
      attr_accessor :path
      attr_accessor :user

      def initialize(uri)
        @uri = uri
      end

      def to_s
        @uri
      end
    end
  end
end
