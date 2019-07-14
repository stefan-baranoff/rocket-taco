require "json"
require "sinatra"

require_relative 'api'
require_relative 'db'

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
  global_int = false
  for int in $ints
    if int[0].include? "Rocket Taco"
      if int[0].include? "Global"
        global_int = true
      end
      $channel_stat[int[2][0][1..-1]] = "Connected"
    end
  end
  if global_int == false
    Api.addGlobalInt $server, $port, $user, $userId, $authToken
  end
end

update $server, $port, $user, $password
db = Db.init $channels

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
    Api.addCreateInt $server, $port, $user, $userId, $authToken, params[:channels]
  end
  update $server, $port, $user, $password
  redirect "/"
end

post "/taco" do
  req= JSON.parse(request.body.read)
  user, msg = req["user_name"], req["text"]
  quant = 0
  users = []
  reason = []
  for word in msg.split(" ")
    if word[0] == "@"
      users.push(word[1..-1])
    elsif word == ":taco:"
      quant += 1
    else
      reason.push(word)
    end
  end
  reason = reason.join " "
  if Db.insertTaco db, params[:channel], user, users, quant, reason
    puts "#{user} gave #{quant} tacos to #{users} for reason: #{reason} on channel #{params[:channel]}"
    Api.directMessage $server, $port, $userId, $authToken, user, "You have successfully given #{quant} tacos to #{users.join(', ')}!"
  else
    Api.directMessage $server, $port, $userId, $authToken, user, "You don't have enough tacos to give #{quant} taco(s) to #{users.join(', ')}"
  end
end

post "/command" do
  req= JSON.parse(request.body.read)
  user, msg, channel = req["user_name"], req["text"], req["channel_id"]
  if msg.include? "tacos"
    tacos = Db.getTacos db, user
    Api.sendMessage $server, $port, $userId, $authToken, channel, "You have #{tacos} tacos"
  end
end

get "/icon.png" do
  send_file 'views/icon.png'
end
