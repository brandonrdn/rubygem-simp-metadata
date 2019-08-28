# vim: set expandtab ts=2 sw=2:
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name = 'simp-metadata'
  s.date = `git log -1 --format=%ai | awk '{print $1}'`
  s.version = `git describe --always`
  s.summary = 'SIMP Metadata Library'
  s.description = 'A library for accessing the SIMP metadata format for the simp project'
  s.authors = [
    'Brandon Riden',
    'Dylan Cochran'
  ]
  s.executables      = `git ls-files -- exe/*`.split("\n").map { |f| File.basename(f) }
  s.bindir           = 'exe'
  s.email = 'simp@simp-project.org'
  s.license = 'Apache-2.0'
  s.homepage = 'https://github.com/simp/rubygem-simp-metadata'
  s.files = Dir['Rakefile', '{bin,lib,spec}/**/*', 'README*', 'LICENSE*']
  s.add_runtime_dependency 'require_all', '~> 2.0'
  s.add_development_dependency 'pry', '~> 0.12'
  s.add_development_dependency 'rake', '~> 11.3'
  s.add_development_dependency 'redcarpet', '~> 3.5'
  s.add_development_dependency 'reek', '~> 5.4'
  s.add_development_dependency 'rspec-command', '~> 1.0'
  s.add_development_dependency 'rubocop', '~> 0.41'
  s.add_development_dependency 'rubygems-tasks', '~> 0.2'
  s.add_development_dependency 'simplecov', '~> 0.17'
  s.add_development_dependency 'yard', '~> 0.9'
  s.add_development_dependency 'yard-sinatra', '~> 1.0'
  s.add_development_dependency 'yardstick', '~> 0.9'
end
