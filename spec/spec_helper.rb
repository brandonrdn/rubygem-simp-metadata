require 'simplecov'
$simp_metadata_debug_level = 'debug2'
$simp_metadata_debug_output_disabled = true
SimpleCov.minimum_coverage 70
#SimpleCov.minimum_coverage_by_file 30
SimpleCov.start do
  add_filter "/vendor/"
end
