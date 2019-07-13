require 'httparty'

module Api

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

  def Api.addInt server, port, user, userId, authToken, channel
    url = Api.getUrl server, port, "integrations.create"
    headers = Api.getHeaders userId, authToken
    data = {
      :type => "webhook-outgoing",
      :name => "Rocket Taco for #{channel}",
      :enabled => true,
      :event => "sendMessage",
      :username => user,
      :urls => ["http://localhost:4567/taco?channel=#{channel}"],
      :triggerWords => [":taco:"],
      :channel => "##{channel}",
      :scriptEnabled => false
    }
    puts data.to_json()
    puts HTTParty.post(url, :headers => headers, :body => data.to_json()).parsed_response
  end

  def Api.getChanId server, port, userId, authToken, room
    url = Api.getUrl server, port, "channels.info?roomName=#{room}"
    headers = Api.getHeaders userId, authToken
    HTTParty.get(url, :headers => headers).parsed_response["channel"]["_id"]
  end

  def Api.getChanMessage server, port, userId, authToken, room
    chanId = Api.getChanId server, port, userId, authToken, room
    url = Api.getUrl server, port, "channels.history?roomId=#{chanId}&count=1"
    headers = Api.getHeaders userId, authToken
    resp = HTTParty.get(url, :headers => headers).parsed_response
    puts resp
    [resp["messages"][0]["u"]["username"], resp["messages"][0]["msg"]]
  end

  # def Api.directMessage server, port, userId, authToken, user, msg
  #   direct_messages = Api.listDirectMessages server, port, userId, authToken
  #   room = nil
  #   for direct_message in direct_messages
  #     users = Api.directMessageUsers(server, port, userId, authToken, direct_message)
  #     if users.include? user
  #       room = direct_message
  #       break
  #     end
  #   end
  #   if room == nil
  #     room = Api.createDirectMessage server, port, userId, authToken, user
  #   end
  #   Api.sendMessage
  # end

end
