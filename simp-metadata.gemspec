# vim: set expandtab ts=2 sw=2:
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'simp/metadata/version'

Gem::Specification.new do |s|
  s.name = 'simp-metadata'
  s.date = '2017-05-16'
  s.version = Simp::Metadata::VERSION
  s.summary = 'SIMP Metadata Library'
  s.description = 'A library for accessing the SIMP metadata format for the simp project'
  s.authors = [
    "Dylan Cochran"
  ]
  s.email = 'simp@simp-project.org'
  s.license = 'Apache-2.0'
  s.homepage = 'https://github.com/simp/rubygem-simp-metadata'
  s.files = Dir['Rakefile', '{bin,lib,spec}/**/*', 'README*', 'LICENSE*']
end
