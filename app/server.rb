require "sinatra"

set :bind => "0.0.0.0"

get "/" do
  send_file 'public/index.html'
end

get "/icon.png" do
  send_file 'public/icon.png'
end
