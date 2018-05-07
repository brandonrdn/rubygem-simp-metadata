require 'simp/metadata'

version = ARGV[0]
edition = "enterprise"
#$simp_metadata_debug_level = 'debug2'

engine = Simp::Metadata::Engine.new(nil, nil, edition, {})
repodir = Dir.mktmpdir("cachedir")
components = engine.releases[version].components
versions = []
components.each do |component|
  if (component.component_type == "puppet-module")
      Simp::Metadata.run("cd #{repodir} && git clone #{component.primary.url} #{component.module_name}")
      Simp::Metadata.run("cd #{repodir}/#{component.module_name} && git checkout #{component.branch}")
      ver = `cd #{repodir}/#{component.module_name} && git describe --abbrev=0 --tags`.chomp
      Simp::Metadata.run("cd #{repodir}/#{component.module_name} && git checkout #{ver}")
      ref = `cd #{repodir}/#{component.module_name} && git rev-parse HEAD`.chomp
      component.tag = ver
      component.ref = ref
      puts "#{component.name} - #{component.tag} - #{component.ref}"
  end
end
engine.save
`rm -rf  #{repodir}`