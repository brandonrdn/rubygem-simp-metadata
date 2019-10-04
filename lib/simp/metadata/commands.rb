# TODO: Dynamically load all files
require 'require_all'
require 'simp/metadata/build_handler'
require_all "#{__dir__}/commands"

module Simp
  module Metadata
    # Commands Class
    module Commands
    end
  end
end
