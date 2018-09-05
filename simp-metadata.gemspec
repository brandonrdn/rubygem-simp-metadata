# vim: set expandtab ts=2 sw=2:
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name = 'simp-metadata'
  s.date = '2017-05-16'
  s.version = `git describe --always`
  s.summary = 'SIMP Metadata Library'
  s.description = 'A library for accessing the SIMP metadata format for the simp project'
  s.authors = [
    'Dylan Cochran'
  ]
  s.executables      = `git ls-files -- exe/*`.split("\n").map { |f| File.basename(f) }
  s.bindir           = 'exe'
  s.email = 'simp@simp-project.org'
  s.license = 'Apache-2.0'
  s.homepage = 'https://github.com/simp/rubygem-simp-metadata'
  s.files = Dir['Rakefile', '{bin,lib,spec}/**/*', 'README*', 'LICENSE*']
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'rubygems-tasks'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'yard-sinatra'
  s.add_development_dependency 'yardstick'
  s.add_development_dependency 'reek'
  s.add_development_dependency 'rspec-command'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
end
