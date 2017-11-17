require 'spec_helper'
require 'simp/metadata'
describe Simp::Metadata::Engine do

  it "should instantiate without errors" do
    expect {
      engine = Simp::Metadata::Engine.new

      engine.cleanup()
      engine = nil
    }.not_to raise_error()
  end
  it "dirty? should return false" do

    engine = Simp::Metadata::Engine.new
    expect(engine.dirty?).to eql(false)
    engine.cleanup()
    engine = nil
  end
  it "save should run without errors" do
    expect {
      engine = Simp::Metadata::Engine.new

      engine.save()
      engine.cleanup()
      engine = nil
    }.not_to raise_error()
  end
  it "cleanup should run without errors" do
    expect {
      engine = Simp::Metadata::Engine.new

      engine.cleanup()
      engine = nil
    }.not_to raise_error()
  end
  describe "components" do
      it "should run without errors" do
        expect {
          engine = Simp::Metadata::Engine.new

          engine.components()
          engine = nil
        }.not_to raise_error()
      end
      it "should return a Simp::Metadata::Components object" do
        engine = Simp::Metadata::Engine.new
        expect(engine.components.class.to_s).to eql("Simp::Metadata::Components")
        engine.cleanup()
        engine = nil
      end
  end
  describe "releases" do
    it "should run without errors" do
      expect {
        engine = Simp::Metadata::Engine.new

        engine.releases()
        engine = nil
      }.not_to raise_error()
    end
    it "should return a Simp::Metadata::Releases object" do
      engine = Simp::Metadata::Engine.new
      expect(engine.releases.class.to_s).to eql("Simp::Metadata::Releases")
      engine.cleanup()
      engine = nil
    end
  end

end