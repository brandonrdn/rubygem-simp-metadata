require 'spec_helper'
require 'simp/media'

describe Simp::Media::Engine do
  it "should throw an error if input_type is nil" do
    expect { engine = Simp::Media::Engine.new({"version" => "test-stub", "input_type" => nil}) }.to raise_error(RuntimeError, "input_type must be specified")
  end
  it "should throw an error if output_type is nil" do
    expect { engine = Simp::Media::Engine.new({"version" => "test-stub", "output_type" => nil}) }.to raise_error(RuntimeError, "output_type must be specified")
  end
  it "should instantiate without errors" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    engine = Simp::Media::Engine.new({"version" => "test-stub", "edition" => "community", "output_type" => "tar", "output" => "#{tempdir}/test.tgz"})
    expect(engine.loaded?).to match(true)
    engine.cleanup()
    engine = nil
    FileUtils.rmtree(tempdir)
  end
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