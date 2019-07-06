#!/env/bin/ruby

require_relative 'argparser'
require_relative 'api'

args = ArgParser.parse ARGV
server = args['-s']
port = args['-p']
channel = args['-c']
user = args['-u']
password = args['-P']

userId, authToken = Api.login server, port, user, password
ims = Api.ims server, port, userId, authToken
Api.messages server, port, userId, authToken, ims[0]
