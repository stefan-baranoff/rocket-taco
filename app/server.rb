require "sinatra"

set :bind => "0.0.0.0"

server = "localhost"
port = 3000
user = "rocket_taco"
password = "taco"
status = "Not Connected"

get "/" do
  locals = {:server=>server, :port=>port, :user=>user, :password=>password, :status=>status}
  erb :index, :locals => locals
end

get "/update" do
  server = params[:server]
  port = params[:port]
  user = params[:user]
  password = params[:password]
  status = "Connecting"
  redirect "/"
end

get "/icon.png" do
  send_file 'views/icon.png'
end
