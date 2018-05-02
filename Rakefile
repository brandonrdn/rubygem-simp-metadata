#
# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.


require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rubygems/package_task'
require 'rake/testtask'
require 'rspec/core/rake_task'


Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
end

begin
  require 'rubygems/tasks'
  Gem::Tasks.new
rescue LoadError
end

begin

# yardstick

# measure coverage
require 'yardstick/rake/measurement'

Yardstick::Rake::Measurement.new(:yardstick_measure) do |measurement|
  measurement.output = 'measurement/report.txt'
end


# verify coverage

require 'yardstick/rake/verify'

Yardstick::Rake::Verify.new(:yardstick_verify) do |verify|
  verify.threshold = 50
  verify.require_exact_threshold = false
end
rescue LoadError
end

begin 

# reek
require 'reek/rake/task'

Reek::Rake::Task.new do |t|
  t.fail_on_error = false
end
rescue LoadError
end

