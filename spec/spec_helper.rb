require 'simplecov'
#SimpleCov.minimum_coverage 60
#SimpleCov.minimum_coverage_by_file 30
SimpleCov.start do
  add_filter "/vendor/"
end
