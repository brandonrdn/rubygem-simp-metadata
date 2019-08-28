#
# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'rubygems'
require 'rubygems/package_task'
#require 'simp/rake/rubygem'

#Simp::Rake::Rubygem.new('simp-rake-helpers', File.dirname(__FILE__))

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  fail("Load Error for RSpec::Core::RakeTask")
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
task :update_version, [:version] do |task, args|
  require 'erb'
  gem_version = args[:version]
  renderer = ERB.new(File.read('lib/simp/metadata/version.erb'))
  res = renderer.result(binding)
  File.open("lib/simp/metadata/version.rb", "w+") do |f|
    f.write(res)
  end
end

task :prerelease, [:version] do |task, args|
  Rake::Task["update_version"].invoke(args[:version])
end

namespace :release do
  desc "Build a Release"
	task :build, [:version] do |task, args|
    branch=`git rev-parse --abbrev-ref HEAD`.chomp
    version = args[:version]
    if (branch != "develop")
      puts "CRITICAL: releases must be made off of develop"
    else
      puts `git fetch origin`
      messagelog = []
      messagelog << "Release #{version}"
      messagelog << ""
      `git log --pretty="%s" origin/master...develop`.gsub("'", "\"").chomp.split("\n").each { |l| messagelog << l }
      releasemessage = messagelog.join("\n")
      puts `git pull origin`
      puts `git checkout master`
      puts `git pull origin`
      puts `git merge -m '#{releasemessage}' --no-ff develop`
      Rake::Task["prerelease"].invoke(version)
      puts `git add -A`
      puts `git commit --amend -m '#{releasemessage}'`
      puts `git tag -s -m 'Release #{version}' #{version}`
      puts `git checkout develop`
      puts `git merge master`
    end
	end
  task :push do
    puts `git push origin --tags`
    puts `git push origin develop:develop`
    puts `git push origin master:master`
  end
end

