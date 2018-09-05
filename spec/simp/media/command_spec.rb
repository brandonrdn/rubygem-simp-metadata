require_relative '../../spec_helper'
require 'simp/media'
require 'simp/media/command'

describe Simp::Media::Command do
  xit 'Should display help when no options are passed' do
    # Create an output capture system.
    command = Simp::Media::Command.new
    command.run([])
  end
end
