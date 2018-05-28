require 'resque-retry'
require 'resque-retry/server'

# Make sure to require your workers & application code below this line:
require 'qb'
require 'qb/jobs'

# Run the server
run Resque::Server.new
