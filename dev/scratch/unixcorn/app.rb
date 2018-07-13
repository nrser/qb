require "sinatra/base"

class App < Sinatra::Base

  get '/' do
    'Hello from UNIXcorn!'
  end

end