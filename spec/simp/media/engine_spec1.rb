require 'spec_helper'
require 'simp/media'

describe Simp::Media::Engine do

  it "should instantiate without errors" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    engine = Simp::Media::Engine.new({"output" => "file://#{tempdir}/control-repo"})
    expect(engine.loaded?).to match(true)
    engine.cleanup()
    engine = nil
    FileUtils.rmtree(tempdir)
  end

end