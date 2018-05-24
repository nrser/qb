require 'nrser'
require 'qb/jobs'

class HelloJob < QB::Jobs::Job
  include NRSER::Log::Mixin
  
  def perform
    logger.info "Saying Hello!"
    
    dest = QB::ROOT / 'tmp' / 'hello.txt'
    
    dest.open 'w' do |f|
      5.times.each do |i|
        f.puts "Hello AGAIN ##{ i }!"
        notify "Said #{ i }!"
        sleep 1
      end
    end
    
    sleep
    
    logger.info "Done-zo!"
  end
end
