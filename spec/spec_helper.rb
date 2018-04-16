require 'simplecov'
$simp_metadata_debug_level = 'debug2'
$simp_metadata_debug_output_disabled = true
#SimpleCov.minimum_coverage 70
#SimpleCov.minimum_coverage_by_file 30
SimpleCov.start do
  add_filter "/vendor/"
end

def component_diff_instance(release1,release2, component, attribute)
  engine = Simp::Metadata::Engine.new(nil, nil)
  component1 = engine.releases[release1].components[component]
  component2 = engine.releases[release2].components[component]
  component1.diff(component2,attribute)
end

def component_view_instance(release, component, attribute)
  engine = Simp::Metadata::Engine.new(nil, nil, version=release)
  comp = engine.releases[release].components[component]
  comp.view(attribute)
end

def release_diff_instance(release1, release2, attribute)
  engine = Simp::Metadata::Engine.new(nil, nil, edition='enterprise')
  release1 = engine.releases[release1]
  release2 = engine.releases[release2]
  release1.diff(release2,attribute)
end

