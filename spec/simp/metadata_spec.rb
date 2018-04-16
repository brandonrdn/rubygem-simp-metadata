 require 'spec_helper'
require 'simp/metadata'

shared_examples_for "log_wrapper" do |method_name|
  it "should not throw an error" do
    $simp_metadata_debug_level = 'debug2'
    tempdir = Dir.mktmpdir("simp-media-rspec")
    expect { Simp::Metadata.send(method_name, "test")}.not_to raise_error
    FileUtils.rmtree(tempdir)
    end
  it "should not throw an error if logging is disabled" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    $simp_metadata_debug_level = 'disabled'
    expect { Simp::Metadata.send(method_name, "test")}.not_to raise_error
    FileUtils.rmtree(tempdir)
    $simp_metadata_debug_level = 'debug2'
  end
  it "should not throw an error if logging is left default" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    $simp_metadata_debug_level = 'ssss'
    expect { Simp::Metadata.send(method_name, "test")}.not_to raise_error
    FileUtils.rmtree(tempdir)
    $simp_metadata_debug_level = 'debug2'
  end
end

shared_examples_for "download_component" do |component|

  it "should not throw an error" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    expect { Simp::Metadata.download_component(component, {"target" => tempdir})}.not_to raise_error
    FileUtils.rmtree(tempdir)
  end
  it "should return a hash" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    retval = Simp::Metadata.download_component(component, {"target" => tempdir})
    expect(retval.class.to_s).to eql("Hash")
    FileUtils.rmtree(tempdir)
  end
  it "should return a path key" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    retval = Simp::Metadata.download_component(component, {"target" => tempdir})
    expect(retval.key?("path")).to eql(true)
    FileUtils.rmtree(tempdir)
  end
  it "should return a path key that is within the tempdir" do
    tempdir = Dir.mktmpdir("simp-media-rspec")
    retval = Simp::Metadata.download_component(component, {"target" => tempdir})
    expect(retval["path"]).to match(/^#{tempdir}/)
    FileUtils.rmtree(tempdir)
  end
end
describe Simp::Metadata do
  describe "Simp::Metadata.debug2" do
    it_should_behave_like "log_wrapper", :debug2
  end
  describe "Simp::Metadata.debug1" do
    it_should_behave_like "log_wrapper", :debug1
  end
  describe "Simp::Metadata.info" do
    it_should_behave_like "log_wrapper", :info
  end
  describe "Simp::Metadata.warning" do
    it_should_behave_like "log_wrapper", :warning
  end
  describe "Simp::Metadata.error" do
    it_should_behave_like "log_wrapper", :error
  end
  describe "Simp::Metadata.critical" do
    it_should_behave_like "log_wrapper", :critical
  end
  describe "Simp::Metadata.run" do
    it "should run a command with no errors" do
      # Create an output capture system.
      errorcode = Simp::Metadata.run("echo 'successful'")
      expect(errorcode.success?).to eql(true)
    end
    it "should return an error on a non-zero exit code" do
      # Create an output capture system.
      errorcode = Simp::Metadata.run("false")
      expect(errorcode.success?).to eql(false)
    end
  end
  describe "Simp::Metadata.get_license_data" do

    it "should return a filename and a data stream" do
      # Create an output capture system.
      filename, data = Simp::Metadata.get_license_data(nil)
      expect(filename.class.to_s).to eql("String")
      expect(data.class.to_s).to eql("String")
      expect(File.exists?(filename)).to eql(true)
    end
  end
  describe "Simp::Metadata.download_component" do
    it "should throw an error if target is not specified" do
      expect { Simp::Metadata.download_component(nil, {})}.to raise_error(RuntimeError, "Must specify 'target'")
    end
    it "should throw an error if component is nil" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      expect { Simp::Metadata.download_component(nil, {"target" => tempdir})}.to raise_error(RuntimeError, "component.class=NilClass, NilClass is not in ['String', 'Simp::Metadata::Component']")
      FileUtils.rmtree(tempdir)
    end
    it "should throw an error if component is not a string or Simp::Metadata::Component" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      expect { Simp::Metadata.download_component([], {"target" => tempdir})}.to raise_error(RuntimeError, "component.class=Array, Array is not in ['String', 'Simp::Metadata::Component']")
      FileUtils.rmtree(tempdir)
    end
    describe "when component == 'simp-metadata'" do
      it_should_behave_like "download_component", 'simp-metadata'
    end
    describe "when component is a Simp::Metadata::Component" do
      engine = Simp::Metadata::Engine.new()
      component = engine.components["pupmod-simp-activemq"]
      it_should_behave_like "download_component", component
    end
    if (ENV.fetch("SIMP_LICENSE_KEY", nil) != nil)
      describe "when component == 'enterprise-metadata'" do
        it_should_behave_like "download_component", 'enterprise-metadata'
      end
    end
  end

  describe "Simp::Metadata.fetch_from_url" do

    it "should throw an error when urlspec is a 'ftp' String" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      expect { Simp::Metadata.fetch_from_url("ftp://github.com/simp/simp-metadata/archive/master.zip","#{tempdir}/master.zip",'simp-metadata', {"target" => tempdir})}.to raise_error(RuntimeError, "unsupported url type ftp")
      FileUtils.rmtree(tempdir)
    end
    it "should not throw an error when urlspec is an https String" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      expect { Simp::Metadata.fetch_from_url("https://github.com/simp/simp-metadata/archive/master.zip","#{tempdir}/master.zip",'simp-metadata', {"target" => tempdir})}.not_to raise_error
      FileUtils.rmtree(tempdir)
    end
    it "should not throw an error when urlspec is an http String" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      expect { Simp::Metadata.fetch_from_url("http://github.com/simp/simp-metadata/archive/master.zip","#{tempdir}/master.zip",'simp-metadata', {"target" => tempdir})}.not_to raise_error
      FileUtils.rmtree(tempdir)
    end
    it "should not throw an error when urlspec is a hash with just a 'url' element" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      expect { Simp::Metadata.fetch_from_url({"url" => "https://github.com/simp/simp-metadata/archive/master.zip"},"#{tempdir}/master.zip",'simp-metadata', {"target" => tempdir})}.not_to raise_error
      FileUtils.rmtree(tempdir)
    end
    it "should not throw an error when type == file" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      expect { Simp::Metadata.fetch_from_url({"type" => "file", "url" => "https://github.com/simp/simp-metadata/archive/master.zip"},"#{tempdir}/master.zip",'simp-metadata', {"target" => tempdir})}.not_to raise_error
      FileUtils.rmtree(tempdir)
    end
    it "should not throw an error when type == git" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      expect { Simp::Metadata.fetch_from_url({"type" => "git", "url" => "https://github.com/simp/simp-metadata"},"#{tempdir}/simp-metadata",'simp-metadata', {"target" => tempdir})}.not_to raise_error
      # Test git pull origin code path as well
      expect { Simp::Metadata.fetch_from_url({"type" => "git", "url" => "https://github.com/simp/simp-metadata"},"#{tempdir}/simp-metadata",'simp-metadata', {"target" => tempdir})}.not_to raise_error
      FileUtils.rmtree(tempdir)
    end
  end

  describe "Simp::Metadata.fetch_simp_enterprise" do
    it "should not throw an error when location is a location" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      engine = Simp::Metadata::Engine.new()
      component = engine.components["pupmod-simp-activemq"]
      expect { Simp::Metadata.fetch_simp_enterprise(component.primary.url,"#{tempdir}/simp-metadata",component, component.primary, {"target" => tempdir})}.not_to raise_error
      FileUtils.rmtree(tempdir)
    end
    xit "should not throw an error when downloading a simp-metadata url" do
      tempdir = Dir.mktmpdir("simp-media-rspec")
      engine = Simp::Metadata::Engine.new(nil, nil, "enterprise")
      component = engine.components["enterprise-metadata"]
      expect { Simp::Metadata.fetch_simp_enterprise(component.primary.url,"#{tempdir}/simp-metadata",component, component.primary, {"target" => tempdir})}.not_to raise_error
      FileUtils.rmtree(tempdir)
    end
  end
end
