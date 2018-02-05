require 'spec_helper'
require 'simp/media'

describe Simp::Media::Type::Tar do

  it "should run without errors" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    engine = Simp::Media::Engine.new({"version" => "test-stub", "edition" => "community", "output_type" => "tar", "output" => "#{tempdir}/test.tgz"})
    expect(engine.loaded?).to match(true)
    engine.run
    engine.cleanup()
    engine = nil
    FileUtils.rmtree(tempdir)
  end

end