require_relative '../../spec_helper'
require 'simp/metadata'
require 'simp/metadata/commands/clone'

describe Simp::Metadata::Release do
  describe '#puppetfile' do
    context 'when type == nil' do
      it 'should return a String' do
        engine = Simp::Metadata::Engine.new
        release = engine.releases['test-stub']
        puppetfile = release.puppetfile
        expect(puppetfile.class.to_s).to eql('String')
        engine.cleanup
        engine = nil
      end

      it 'should return a valid Puppetfile' do
        engine = Simp::Metadata::Engine.new
        release = engine.releases['test-stub']
        puppetfile = release.puppetfile
        expect(puppetfile.split("\n").size).to be > 2
        expect(puppetfile).to match(/^mod.*'.*',/)
        expect(puppetfile).to match(/^\s{2}:git => 'https:\/\/github.com.*',/)
        expect(puppetfile).to match(/^\s{2}:tag => '[0-9]+.[0-9]+.[0-9]+'/)
        engine.cleanup
        engine = nil
      end
    end

    context "when type == 'simp-core'" do
      it 'should return a String' do
        engine = Simp::Metadata::Engine.new
        release = engine.releases['test-stub']
        puppetfile = release.puppetfile('simp-core')
        expect(puppetfile.class.to_s).to eql('String')
        engine.cleanup
        engine = nil
      end

      it 'should return a valid Puppetfile' do
        engine = Simp::Metadata::Engine.new
        release = engine.releases['test-stub']
        puppetfile = release.puppetfile('simp-core')
        expect(puppetfile.split("\n").size).to be > 2
        expect(puppetfile).to match(/^mod.*'.*',/)
        expect(puppetfile).to match(/^\s{2}:git => 'https:\/\/github.com.*',/)
        expect(puppetfile).to match(/^\s{2}:tag => '[0-9]+.[0-9]+.[0-9]+'/)
        engine.cleanup
        engine = nil
      end
    end
  end
  describe '#diff' do
    context 'when attribute is nil' do
      it 'should return all differences' do
        attribute = nil
        test = release_diff_instance(attribute)
        expect(test).to eql(
          'pupmod-simp-activemq' => {
            'branch' => {
              'original' => 'master',
              'changed' => 'develop'
            },
            'tag' => {
              'original' => '1.1.1',
              'changed' => '1.1.2'
            },
            'ref' => {
              'original' => '488f5a0d5b53063c125b93a596626193b71aaa08',
              'changed' => '3987ra0d5b53063f493b93a596626193b71dddd4'
            },
            'version' => {
              'original' => '1.1.1',
              'changed' => '1.1.2'
            }
          }
        )
      end
    end
    context 'when attribute is "version"' do
      it 'should return only version' do
        attribute = 'version'
        test = release_diff_instance(attribute)
        expect(test).to eql(
          'pupmod-simp-activemq' => {
            'version' => {
              'original' => '1.1.1',
              'changed' => '1.1.2'
            }
          }
        )
      end
    end
  end
end

# vim: set expandtab ts=2 sw=2:
