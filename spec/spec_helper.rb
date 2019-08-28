require 'simplecov'

Simp::Metadata.debug_level('debug2')
Simp::Metadata.disable_debug_output(true)

# SimpleCov.minimum_coverage 70
# SimpleCov.minimum_coverage_by_file 30

if Dir.exist?(File.expand_path('../../lib', __FILE__))
  require 'coveralls'
  require 'simplecov'
  require 'simplecov-console'
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]
  SimpleCov.start do
    track_files 'lib/**/*.rb'
    add_filter '/spec'
    add_filter '/vendor'
    add_filter '/.vendor'
  end
end

def test_component(engine = nil)
  engine = Simp::Metadata::Engine.new if engine.nil?
  engine.releases['test-stub'].components['pupmod-simp-activemq']
end

def diff_component(engine = nil)
  engine = Simp::Metadata::Engine.new if engine.nil?
  engine.releases['test-diff'].components['pupmod-simp-activemq']
end

def component_diff_instance(attribute)
  engine = Simp::Metadata::Engine.new
  component1 = test_component(engine)
  component2 = diff_component(engine)
  component1.diff(component2, attribute)
end

def component_view_instance(attribute)
  comp = test_component
  comp.view(attribute)
end

def release_diff_instance(attribute)
  engine = Simp::Metadata::Engine.new
  release1 = engine.releases['test-stub']
  release2 = engine.releases['test-diff']
  release1.diff(release2, attribute)
end
