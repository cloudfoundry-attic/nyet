require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |c|
  c.rspec_opts = %w(--format documentation --color)
end

task :default => :spec
