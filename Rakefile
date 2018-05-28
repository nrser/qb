require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "resque/tasks"
require 'resque/scheduler/tasks'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :resque do
  
  task :setup do
    ENV['COUNT'] = '5'
    ENV['QUEUE'] = '*'
    
    require 'resque-retry'
    require 'resque/failure/redis'
    
    Resque.after_fork do |job|
      require 'qb'
      require 'qb/jobs'
      
      QB::Jobs.after_fork_prepare_for_job job
    end
    
    Resque::Failure::MultipleWithRetrySuppression.classes = \
      [ Resque::Failure::Redis ]
    
    Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression
  end
  
end
