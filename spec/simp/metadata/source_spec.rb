require_relative '../../spec_helper'
require 'simp/metadata'

# Need to fix test
describe Simp::Metadata::Source do
  it 'should require a URL to be specified' do
    expect do
      source = Simp::Metadata::Source.new(args)
    end.to raise_error(ArgumentError)
  end
  # it "should instantiate when passed a valid metadata source" do
  #   expect {
  #     source = Simp::Metadata::Source.new("file://#{File.dirname(__FILE__)}/mock_source")
  #     source.cleanup
  #     source = nil
  #   }.not_to raise_error
  #   end
  # it "should instantiate when passed a valid metadata source and a cachepath" do
  #   expect {
  #     tempdir = Dir.mktmpdir("simp-metadata-rspec-")
  #     source = Simp::Metadata::Source.new("file://#{File.dirname(__FILE__)}/mock_source", tempdir)
  #     source.cleanup
  #     source = nil
  #     FileUtils.rmtree(tempdir)
  #   }.not_to raise_error
  # end
end
