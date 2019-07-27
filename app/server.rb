require "json"
require "sinatra"

require_relative 'api'
require_relative 'db'

set :bind => "0.0.0.0"

db = Db.init []
$host, $host_port, $server, $port, $user, $password = Db.loadSettings db

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
  if $status == "Connected"
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
      Api.addGlobalInt $server, $port, $user, $userId, $authToken,  $host, $host_port
    end
    Api.setAvatar $server, $port, $userId, $authToken, $host, $host_port
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
    :channel_stat=>$channel_stat,
    :host=>$host,
    :host_port=>$host_port
  }
  erb :index, :locals => locals
end

get "/update" do
  host_changed = ($host != params[:host]) || ($host_port) != (params[:host_port])
  $host = params[:host]
  $host_port = params[:host_port]
  $server = params[:server]
  $port = params[:port]
  $user = params[:user]
  $password = params[:password]
  Db.saveSettings db, $host, $host_port, $server, $port, $user, $password
  if params[:channels]
    Api.removeChannelInt $server, $port, $userId, $authToken, params[:channels]
    Api.addChannelInt $server, $port, $user, $userId, $authToken, params[:channels], $host, $host_port
  end
  if host_changed
    for channel in $channel_stat.keys()
      if ($channel_stat[channel] == "Connected")
        Api.removeChannelInt $server, $port, $userId, $authToken, channel
        Api.addChannelInt $server, $port, $user, $userId, $authToken, channel, $host, $host_port
      end
    end
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
  if users.include? user
    Api.directMessage $server, $port, $userId, $authToken, user, "You cannot give tacos to yourself."
  elsif Db.insertTaco db, params[:channel], user, users, quant, reason
    Api.directMessage $server, $port, $userId, $authToken, user, "You have successfully given #{quant} tacos to @#{users.join(', @')}!"
    for receiver in users
      Api.directMessage $server, $port, $userId, $authToken, receiver, "You have received #{quant} tacos from @#{user}!"
    end
  else
    Api.directMessage $server, $port, $userId, $authToken, user, "You don't have enough tacos to give #{quant} taco(s) to #{users.join(', ')}"
  end
end

post "/command" do
  req= JSON.parse(request.body.read)
  user, msg, channel = req["user_name"], req["text"], req["channel_id"]
  if msg.include? "!tacos"
    tacos = Db.getTacos db, user
    Api.sendMessage $server, $port, $userId, $authToken, channel, "You have #{tacos} tacos"
  end
  if msg.include? "!help"
    help = %q(

      *Giving tacos*
           - Give tacos by sending a message including :taco: emojis and @username(s)
           - Number of :taco: emoji specifies the number of tacos to give
           - Can have multiple recipients
               - E.g. :taco: :taco: @user1 @user2 will give 2 tacos to user1 and 2 tacos to user 2
      *Utility Commands*
           - !tacos - how many tacos you have left to give today
           - !leaderboard - display highest taco givers and receivers
           - !help - display this message
    )
    Api.sendMessage $server, $port, $userId, $authToken, channel, help
  end
  if msg.include? "!leaderboard"
    timeframes = {"day" => 1, "week" => 7, "month" => 30, "year" => 365}
    timeframe = 36500
    timeframe_name = "century"
    chan = "GLOBAL"
    for word in msg.split " "
      if timeframes.include? word
        timeframe = timeframes[word]
        timeframe_name = word
      end
      if $channel_stat.include? word.sub("#", "")
        chan = word.sub("#", "")
      end
    end
    rlb, glb = Db.getLeaderBoard db, chan, timeframe, true
    text = "*Leaderboard for ##{chan} this #{timeframe_name}:*\n*Most Tacos Received*\n"
    place = 1
    if rlb.length == 0
      text += "No Tacos Received\n"
    end
    for elem in rlb
      text += "#{place}. #{elem[0]}: #{elem[1]}\n"
      place += 1
    end
    text += "*Most Tacos Given*\n"
    place = 1
    if glb.length == 0
      text += "No Tacos Given\n"
    end
    for elem in glb
      text += "#{place}. #{elem[0]}: #{elem[1]}\n"
      place += 1
    end
    text += "*Your Stats*\n"
    recv_stats = Db.getUserStats db, chan, timeframe, user, "receiver"
    give_stats = Db.getUserStats db, chan, timeframe, user, "giver"
    if recv_stats == nil
      text += "No Tacos Received\n"
    else
      text += "Received #{recv_stats[1]} tacos, place #{recv_stats[0]} on leaderboard\n"
    end
    if give_stats == nil
      text += "No Tacos Given\n"
    else
      text += "Gave #{give_stats[1]} tacos, place #{give_stats[0]} on leaderboard\n"
    end
    text += "\nFull Leaderboard: http://#{$host}:#{$host_port}/leaderboard?timeframe=#{timeframe_name}&channel=#{chan}"
    puts Api.sendMessage $server, $port, $userId, $authToken, channel, text
  end
end

get "/leaderboard" do
  chan = params[:channel] ? params[:channel] : "GLOBAL"
  timeframes = {"day" => 1, "week" => 7, "month" => 30, "year" => 365, "century" => 36500}
  timeframe = params[:timeframe] ? params[:timeframe] : "year"
  length = timeframes[timeframe]
  rlb, glb = Db.getLeaderBoard db, chan, length, false
  channels = []
  for channel in $channel_stat.keys()
    if $channel_stat[channel] == "Connected"
      channels.push channel
    end
  end
  locals = {
    :channel => chan,
    :channels => channels,
    :timeframe => timeframe,
    :rlb => rlb,
    :glb => glb
  }
  erb :leaderboard, :locals => locals
end

get "/icon.png" do
  send_file 'views/icon.png'
end
