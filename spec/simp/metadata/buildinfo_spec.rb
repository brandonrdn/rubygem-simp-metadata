require_relative '../../spec_helper'
require 'simp/metadata'

def test_buildinfo(type)
  Simp::Metadata::Buildinfo.new(test_component, type)
end

def diff_buildinfo(type)
  Simp::Metadata::Buildinfo.new(diff_component, type)
end

describe Simp::Metadata::Buildinfo do
  describe '#keys' do
    it 'should return an Array' do
      expect(test_buildinfo('rpm').keys.class.to_s).to eql('Array')
    end
    it 'should return an Array of Strings' do
      expect(test_buildinfo('rpm').keys.all? { |output| output.class.to_s == 'String' }).to eql(true)
    end
  end
  describe '#type' do
    context "when type == 'rpm'" do
      it 'should return a String' do
        expect(test_buildinfo('rpm').type.class.to_s).to eql('String')
      end
      it "should return 'rpm'" do
        expect(test_buildinfo('rpm').type).to eql('rpm')
      end
    end
  end
  describe "#['type']" do
    context "when type == 'rpm'" do
      it 'should return a String' do
        expect(test_buildinfo('rpm')['type'].class.to_s).to eql('String')
      end
      it "should return 'rpm'" do
        expect(test_buildinfo('rpm')['type']).to eql('rpm')
      end
    end
  end
  describe '#build_method' do
    context "when type == 'rpm'" do
      it 'should return a String' do
        expect(test_buildinfo('rpm').build_method.class.to_s).to eql('String')
      end
      it "should return 'simp-core'" do
        expect(test_buildinfo('rpm').build_method).to eql('simp-core')
      end
    end
    context "when simp-metadata == 'metadata-build'" do
      it "should return 'metadata-build'" do
        expect(diff_buildinfo('rpm').build_method).to eql('metadata-build')
      end
    end
  end
  describe "#['build_method']" do
    context "when type == 'rpm'" do
      it 'should return a String' do
        expect(test_buildinfo('rpm')[:build_method].class.to_s).to eql('String')
      end
      it "should return 'simp-core'" do
        expect(test_buildinfo('rpm')[:build_method]).to eql('simp-core')
      end
    end
  end
end
