require 'httparty'

module Api

  def Api.genToken()
    letters = '0123456789ABCDEF'
    token = ""
    for i in 0..100
      token += letters[rand(16)]
    end
    token
  end

  def Api.getUrl server, port, endpoint
    "http://%s:%d/api/v1/%s" % [server, port, endpoint]
  end

  def Api.getHeaders userId, authToken
    {
      "Content-type" => "application/json",
      "X-User-Id" => userId,
      "X-Auth-Token" => authToken
    }
  end

  def Api.login server, port, user, password
    url = Api.getUrl server, port, "login"
    data = {:user => user, :password => password}
    headers = {"Content-type" => "application/json"}
    begin
      resp = HTTParty.post(url, :body => data.to_json(), :headers => headers)
    rescue
      puts "Error logging in: Failed to connect to server"
      return [false, false]
    end
    if resp.parsed_response["status"] == "error"
      puts "Error logging in: %s" % [resp.parsed_response["error"]]
      return [false, false]
    end
    [resp.parsed_response["data"]["userId"], resp.parsed_response["data"]["authToken"]]
  end

  def Api.listChannels server, port, userId, authToken
    url = Api.getUrl server, port, "channels.list"
    headers = Api.getHeaders userId, authToken
    begin
      resp = HTTParty.get(url, :headers => headers)
    rescue
      return []
    end
    names = []
    for chan in resp.parsed_response["channels"]
      names.push([chan["name"]])
    end
    names
  end

  def Api.listInt server, port, userId, authToken
    url = Api.getUrl server, port, "integrations.list"
    headers = Api.getHeaders userId, authToken
    resp = HTTParty.get(url, :headers => headers)
    names = []
    for int in resp.parsed_response["integrations"]
      names.push([int["name"], int["_id"], int["channel"]])
    end
    names
  end

  def Api.addInt server, port, user, userId, authToken, data
    url = Api.getUrl server, port, "integrations.create"
    headers = Api.getHeaders userId, authToken
    HTTParty.post(url, :headers => headers, :body => data.to_json())
  end

  def Api.removeChannelInt server, port, userId, authToken, channel
    url = Api.getUrl server, port, "integrations.remove"
    headers = Api.getHeaders userId, authToken
    for int in Api.listInt(server, port, userId, authToken)
      if int[0] == "Rocket Taco for #{channel}"
        data = {:type=>"webhook-outgoing", :integrationId=>int[1]}
        HTTParty.post(url, :headers => headers, :body => data.to_json())
      end
    end
  end

  def Api.addChannelInt server, port, user, userId, authToken, channel, host, host_port, urlToken
    data = {
      :type => "webhook-outgoing",
      :name => "Rocket Taco for #{channel}",
      :enabled => true,
      :event => "sendMessage",
      :username => user,
      :urls => ["http://#{host}:#{host_port}/taco?channel=#{channel}&p=#{urlToken}"],
      :triggerWords => [":taco:"],
      :channel => "##{channel}",
      :scriptEnabled => false
    }
    Api.addInt server, port, user, userId, authToken, data
  end

  def Api.addGlobalInt server, port, user, userId, authToken, host, host_port
    data = {
      :type => "webhook-outgoing",
      :name => "Rocket Taco Global",
      :enabled => true,
      :event => "sendMessage",
      :username => user,
      :urls => ["http://#{host}:#{host_port}/command"],
      :channel => "@#{user}",
      :scriptEnabled => false
    }
    Api.addInt server, port, user, userId, authToken, data
  end

  def Api.listDirectMessages server, port, userId, authToken
    url = Api.getUrl server, port, "im.list"
    headers = Api.getHeaders userId, authToken
    resp = HTTParty.get(url, :headers => headers).parsed_response
    ids = []
    for im in resp["ims"]
      ids.push im["_id"]
    end
    ids
  end

  def Api.directMessageUsers server, port, userId, authToken, room
    url = Api.getUrl server, port, "im.members?roomId=#{room}"
    headers = Api.getHeaders userId, authToken
    resp = HTTParty.get(url, :headers => headers).parsed_response
    names = []
    for member in resp["members"]
      names.push member["username"]
    end
    names
  end

  def Api.createDirectMessage server, port, userId, authToken, user
    url = Api.getUrl server, port, "im.create"
    headers = Api.getHeaders userId, authToken
    data = {:username => user}
    resp = HTTParty.post(url, :headers => headers, :body => data.to_json()).parsed_response
    resp["room"]["_id"]
  end

  def Api.sendMessage server, port, userId, authToken, room, msg
    url = Api.getUrl server, port, "chat.postMessage"
    headers = Api.getHeaders userId, authToken
    data = {:roomId => room, :text => msg}
    HTTParty.post(url, :headers => headers, :body => data.to_json())
  end

  def Api.directMessage server, port, userId, authToken, user, msg
    direct_messages = Api.listDirectMessages server, port, userId, authToken
    room = nil
    for direct_message in direct_messages
      users = Api.directMessageUsers(server, port, userId, authToken, direct_message)
      if users.include? user
        room = direct_message
        break
      end
    end
    if room == nil
      room = Api.createDirectMessage server, port, userId, authToken, user
    end
    Api.sendMessage server, port, userId, authToken, room, msg
  end

  def Api.setAvatar server, port, userId, authToken, host, host_port
    url = Api.getUrl server, port, "users.setAvatar"
    headers = Api.getHeaders userId, authToken
    data = {:avatarUrl => "http://#{host}:#{host_port}/icon.png"}
    puts HTTParty.post(url, :headers => headers, :body => data.to_json()).parsed_response
  end

end
