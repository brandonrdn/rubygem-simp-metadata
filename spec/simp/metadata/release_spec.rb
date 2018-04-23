require 'spec_helper'
require 'simp/metadata'
describe Simp::Metadata::Release do

  context "when type == nil" do

    it "should return a String" do
      engine = Simp::Metadata::Engine.new
      release = engine.releases['test-stub']
      puppetfile = release.puppetfile()
      expect(puppetfile.class.to_s).to eql("String")
      engine.cleanup()
      engine = nil
    end

    it "should return a valid Puppetfile" do
      engine = Simp::Metadata::Engine.new
      release = engine.releases['test-stub']
      puppetfile = release.puppetfile()
      expect(puppetfile.split("\n").size).to be > 2
      expect(puppetfile).to match(/^mod.*\'.*\',/)
      expect(puppetfile).to match(/^  :git => .*\'.*\',/)
      expect(puppetfile).to match(/^  :ref => .*\'.*\'/)
      engine.cleanup()
      engine = nil
    end
  end

  context "when type == 'simp-core'" do

    it "should return a String" do
      engine = Simp::Metadata::Engine.new
      release = engine.releases['test-stub']
      puppetfile = release.puppetfile('simp-core')
      expect(puppetfile.class.to_s).to eql("String")
      engine.cleanup()
      engine = nil
    end

    it "should return a valid Puppetfile" do
      engine = Simp::Metadata::Engine.new
      release = engine.releases['test-stub']
      puppetfile = release.puppetfile('simp-core')
      expect(puppetfile.split("\n").size).to be > 2
      expect(puppetfile).to match(/^mod.*\'.*\',/)
      expect(puppetfile).to match(/^  :git => .*\'.*\',/)
      expect(puppetfile).to match(/^  :ref => .*\'.*\'/)
      engine.cleanup()
      engine = nil
    end

  end

end
