require 'httparty'

module Api

  def Api.login server, port, user, password
    url = "http://%s:%d/api/v1/login" % [server, port]
    data = {:user => user, :password => password}
    headers = {"Content-type" => "application/json"}
    resp = HTTParty.post(url, :body => data.to_json(), :headers => headers)
    if resp.parsed_response["status"] == "error"
      puts "Error logging in: %s" % [resp.parsed_response["error"]]
      exit 2
    end
    [resp.parsed_response["data"]["userId"], resp.parsed_response["data"]["authToken"]]
  end

end
