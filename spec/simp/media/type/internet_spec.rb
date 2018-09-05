require_relative '../../../spec_helper'
require 'simp/media'

describe Simp::Media::Type::Internet do
  describe "with edition == 'community'" do
    it 'should run without errors' do
      tempdir = Dir.mktmpdir('simp-media-rspec')
      engine = Simp::Media::Engine.new('version' => 'test-stub', 'edition' => 'community', 'output_type' => 'tar', 'output' => "#{tempdir}/test.tgz")
      expect(engine.loaded?).to match(true)
      engine.run
      engine.cleanup
      engine = nil
      FileUtils.rmtree(tempdir)
    end
  end
  if ENV.fetch('SIMP_LICENSE_KEY', nil) != nil
    describe "with edition == 'enterprise'" do
      it 'should run without errors' do
        tempdir = Dir.mktmpdir('simp-media-rspec')
        engine = Simp::Media::Engine.new('version' => 'test-stub', 'edition' => 'enterprise', 'output_type' => 'tar', 'output' => "#{tempdir}/test.tgz")
        expect(engine.loaded?).to match(true)
        engine.run
        engine.cleanup
        engine = nil
        FileUtils.rmtree(tempdir)
      end
    end
  end
end
