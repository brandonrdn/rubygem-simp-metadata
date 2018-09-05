require_relative '../../../spec_helper'
require 'simp/media'

describe Simp::Media::Type::Control_repo do
  it 'should throw an error if output is nil' do
    expect { engine = Simp::Media::Engine.new('version' => 'test-stub', 'output' => nil) }.to raise_error(RuntimeError, 'output must be specified for control-repo output')
  end
  it "should throw an error if output is not a git repo and it's not a local directory" do
    expect { engine = Simp::Media::Engine.new('version' => 'test-stub', 'output' => 'https://localhost:6666/repo.git') }.to raise_error(RuntimeError, 'output is not a valid control-repo')
  end

  it 'should create a bare repo when .git is part of the path' do
    tempdir = Dir.mktmpdir('simp-media-rspec')
    engine = Simp::Media::Engine.new('version' => 'test-stub', 'output' => "file://#{tempdir}/control-repo.git")
    expect(engine.loaded?).to match(true)
    engine.run
    engine.cleanup
    engine = nil
    FileUtils.rmtree(tempdir)
  end
end
