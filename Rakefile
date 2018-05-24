require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "resque/tasks"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :resque do
  
  task :setup do
    ENV['COUNT'] = '1'
    ENV['QUEUE'] = 'qb'
    require 'qb/jobs'
  end
  
end
