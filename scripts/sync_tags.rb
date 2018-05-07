require 'simp/metadata'

version = ARGV[0]
edition = "enterprise"
$simp_metadata_debug_level = 'debug2'

engine = Simp::Metadata::Engine.new(nil, nil, edition, {})
repodir = Dir.mktmpdir("cachedir")
components = engine.releases[version].components
versions = []
components.each do |component|
  if (component.component_type == "puppet-module")
    if (component.tag == nil)
      Simp::Metadata.run("cd #{repodir} && git clone #{component.primary.url} #{component.module_name}")
      Simp::Metadata.run("cd #{repodir}/#{component.module_name} && git checkout #{component.ref}")
      ver = `cd #{repodir}/#{component.module_name} && git describe --always --tags --dirty`.chomp
      component.tag = ver
    end
  end
end
engine.save
`rm -rf  #{repodir}`