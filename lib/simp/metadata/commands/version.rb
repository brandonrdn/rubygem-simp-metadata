require_relative '../commands'
module Simp
  module Metadata
    module Commands
      # Class to display simp-metadata version
      class Version < Simp::Metadata::Commands::Base
        def description
          'Display current simp-metadata version'
        end

        def run(_argv)
          begin
            puts Simp::Metadata::Version.version
          rescue RuntimeError => e
            Simp::Metadata::Debug.critical(e.message)
            exit 5
          end
        end
      end
    end
  end
end
