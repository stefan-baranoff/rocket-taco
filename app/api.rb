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
      return [False, False]
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

end
