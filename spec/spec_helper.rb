require 'simplecov'
$simp_metadata_debug_level = 'debug2'
$simp_metadata_debug_output_disabled = true
#SimpleCov.minimum_coverage 70
#SimpleCov.minimum_coverage_by_file 30
SimpleCov.start do
  add_filter "/vendor/"
end
def test_component(engine = nil)
  if engine == nil
    engine = Simp::Metadata::Engine.new(nil, nil)
  end
  component1 = engine.releases["test-stub"].components["pupmod-simp-activemq"]
end
def diff_component(engine = nil)
  if engine == nil
    engine = Simp::Metadata::Engine.new(nil, nil)
  end
  component1 = engine.releases["test-diff"].components["pupmod-simp-activemq"]
end

def component_diff_instance(release1,release2, component, attribute)
  engine = Simp::Metadata::Engine.new(nil, nil)
  component1 = test_component(engine)
  component2 = diff_component(engine)
  component1.diff(component2,attribute)
end

def component_view_instance(release, component, attribute)
  comp = test_component()
  comp.view(attribute)
end

def release_diff_instance(release1, release2, attribute)
  engine = Simp::Metadata::Engine.new(nil, nil)
  release1 = engine.releases["test-stub"]
  release2 = engine.releases["test-diff"]
  release1.diff(release2,attribute)
end

