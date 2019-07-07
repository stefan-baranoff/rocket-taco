require "sinatra"

require_relative 'api'

set :bind => "0.0.0.0"

server = "localhost"
port = 3000
user = "rocket_taco"
password = "taco"

def login server, port, user, password
  u, a = Api.login server, port, user, password
  if u
    return [u, a, "Connected"]
  end
  ["", "", "Not Connected"]
end

userId, authToken, status = login server, port, user, password
channels = Api.listChannels server, port, userId, authToken

get "/" do
  locals = {:server=>server, :port=>port, :user=>user, :password=>password, :status=>status, :channels=>channels}
  erb :index, :locals => locals
end

get "/update" do
  server = params[:server]
  port = params[:port]
  user = params[:user]
  password = params[:password]
  userId, authToken, status = login server, port, user, password
  channels = Api.listChannels server, port, userId, authToken
  redirect "/"
end

get "/icon.png" do
  send_file 'views/icon.png'
end
