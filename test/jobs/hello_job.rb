require 'qb/jobs'

class HelloJob < QB::Jobs::Job
  def perform
    puts "Hello World"
  end
end
