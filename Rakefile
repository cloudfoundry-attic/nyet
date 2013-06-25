require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'     # use this if you're using RSpec

RSpec::Core::RakeTask.new(:spec) do |c|
  c.rspec_opts = %w(--format documentation --color)
end

task :default => :spec

namespace :spec do
  RSpec::Core::RakeTask.new(:services) do |c|
    c.pattern = 'services_spec/**/*_spec.rb'
    c.rspec_opts = %w(--format documentation --color)
  end
end
