require 'resque-retry'
require 'resque-retry/server'

# Make sure to require your workers & application code below this line:
require 'qb'
require 'qb/jobs'
require 'qb/docker/jobs'

# QB::Jobs.setup!

# Run the server
run Resque::Server.new
