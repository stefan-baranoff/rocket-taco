require "sinatra"

require_relative 'api'

set :bind => "0.0.0.0"

$server = "localhost"
$port = 3000
$user = "rocket_taco"
$password = "taco"
$channels = []
$ints = []
$channel_stat = {}
$userId = ""
$authToken = ""

def login server, port, user, password
  u, a = Api.login server, port, user, password
  if u
    return [u, a, "Connected"]
  end
  ["", "", "Not Connected"]
end

def update server, port, user, password
  $userId, $authToken, $status = login $server, $port, $user, $password
  $channels = Api.listChannels $server, $port, $userId, $authToken
  $ints = Api.listInt $server, $port, $userId, $authToken
  $channel_stat = {}
  for chan in $channels
    $channel_stat[chan[0]] = "Not Connected"
  end
  for int in $ints
    if int[0].include? "Rocket Taco"
      $channel_stat[int[2][0][1..-1]] = "Connected"
    end
  end
end

update $server, $port, $user, $password

get "/" do
  locals = {
    :server=>$server,
    :port=>$port,
    :user=>$user,
    :password=>$password,
    :status=>$status,
    :channels=>$channels,
    :channel_stat=>$channel_stat
  }
  erb :index, :locals => locals
end

get "/update" do
  $server = params[:server]
  $port = params[:port]
  $user = params[:user]
  $password = params[:password]
  if params[:channels]
    Api.addInt $server, $port, $user, $userId, $authToken, params[:channels]
  end
  update $server, $port, $user, $password
  redirect "/"
end

post "/taco" do
  puts params
end

get "/icon.png" do
  send_file 'views/icon.png'
end
