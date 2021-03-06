require_relative '../../spec_helper'
require 'simp/metadata'
require 'simp/metadata/commands/clone'
describe Simp::Metadata::Component do
  describe '#view' do
    context 'when attribute = nil' do
      it 'should return all information' do
        attribute = nil
        test = component_view_instance(attribute)
        expect(test).to eql('asset_name' => 'activemq',
                            'authoritative' => 'true',
                            'branch' => 'master',
                            'component_source' => 'simp-metadata',
                            'component_type' => 'puppet-module',
                            'extension' => 'tgz',
                            'extract' => 'false',
                            'location' => { 'extract' => 'false', 'primary' => 'true', 'method' => 'git', 'url' => 'https://github.com/simp/pupmod-simp-activemq' },
                            'method' => 'git',
                            'module_name' => 'activemq',
                            'ref' => '488f5a0d5b53063c125b93a596626193b71aaa08',
                            'release_source' => 'simp-metadata',
                            'revision' => '0',
                            'tag' => '1.1.1',
                            'target' => 'noarch',
                            'url' => 'https://github.com/simp/pupmod-simp-activemq',
                            'version' => '1.1.1')
      end
    end
    context 'when attribute = version' do
      it 'should return only the version' do
        attribute = 'version'
        test = component_view_instance(attribute)
        expect(test).to eql('version' => '1.1.1')
      end
    end
  end

  describe '#diff' do
    context 'when attribute = nil' do
      it 'should return all information' do
        attribute = nil
        test = component_diff_instance(attribute)
        expect(test).to eql('branch' => { 'original' => 'master', 'changed' => 'develop' },
                            'ref' => { 'original' => '488f5a0d5b53063c125b93a596626193b71aaa08', 'changed' => '3987ra0d5b53063f493b93a596626193b71dddd4' },
                            'tag' => { 'original' => '1.1.1', 'changed' => '1.1.2' },
                            'version' => { 'original' => '1.1.1', 'changed' => '1.1.2' })
      end
    end
    context 'when attribute = version' do
      it 'should return only the version' do
        attribute = 'version'
        test = component_diff_instance(attribute)
        expect(test).to eql('version' => { 'original' => '1.1.1', 'changed' => '1.1.2' })
      end
    end
  end
  describe '#buildinfo' do
    context 'when type = nil' do
      it 'should return a Hash' do
        expect(test_component.buildinfo.class.to_s).to eql('Hash')
      end
      it 'should contain only Simp::Metadata::Buildinfo objects' do
        expect(test_component.buildinfo.all? { |buildinfo| buildinfo.class.to_s == 'Simp::Metadata::Buildinfo' }).to eql(true)
      end
    end

    context "when type = 'rpm'" do
      it 'should return a Simp::Metadata::Buildinfo object' do
        expect(test_component.buildinfo('rpm').class.to_s).to eql('Simp::Metadata::Buildinfo')
      end
      it "should be of type 'rpm'" do
        expect(test_component.buildinfo('rpm').type).to eql('rpm')
      end
      it "should be of build_method 'simp-core'" do
        expect(test_component.buildinfo('rpm').build_method).to eql('simp-core')
      end
    end
  end
end
