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
puts Api.listInt server, port, userId, authToken
