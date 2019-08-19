# Rocket Taco

Rocket Taco is a [Rocket.Chat](https://rocket.chat/) bot inspired by [HeyTaco!](https://www.heytaco.chat/).  Rocket Taco allows you to commend members of your server for their actions.  Simply send a message with the `:taco:` emoji and the user's tag (i.e. `@<user>`) and they will receive a taco from you.  Tacos are recorded and displayed on the leader board for all to see.

## Setup

1. [Install docker](https://docs.docker.com/install/) if you haven't already.
2. Add an admin user to you Rocket.Chat server to represent the Bot.
3. From within the root directory of the repo run the following command to build the docker image:
```
docker build -t rocket_taco .
```
4. Run the following command to start the Bot server:
```
docker run -it --net=host rocket_taco
```
5. Navigate to http://localhost:4567 in your favorite browser.  Fill out the following form fields and hit update at the bottom of the page:
  - Bot IP or FQDN: the IP or FQDN of the Bot server.  Note that the Rocket Chat server will send messages to this IP/Address, so it must be reachable from the Rocket Chat Server.
  - Bot Port: the port that the Bot server is listening on.
  - Rocket.Chat Server: FQDN or IP address of the Rocket Chat Server.  The Bot server must be able to reach this address.
  - Rocket.Chat Port: the port that the Rocket.Chat server is listening on
  - Rocket Taco Username: username of the user created in step 2
  - Rocket Taco Password: password of the user created in step 2
6. The status header at the top of the page should now display `Connected`.  For each channel on which you want Rocket Taco to be active, select the corresponding  radio button under channels and press update.      

## Commands

Send tacos to another user by sending a message containing `:taco:` and `@<user>` to any channel on which Rocket Taco is active.
   - Every word in the message except `:taco:` and `@<user>` are ignored by rocket taco.  This allows you to use the bulk of the message to explain why you are giving `user` tacos.
   - Number of `:taco:` emojis represents the number of tacos to send to `user`.  Note that you can send at most 5 tacos in a 24 hour period.  For example, this message will send 4 tacos to Joe  
   ```
   :taco: :taco: :taco: :taco: @Joe for amazing surprise party!
   ```
   - Can also send to multiple users tacos in the same message.  The following message will send 2 tacos to Sam and 2 tacos to Kate:
   ```
   :taco: :taco: @Sam @Kate for help setting up!
   ```  

Review the leader board and your personal stats by direct messaging the Rocket Taco user.
  - `!tacos` - prints the number of tacos available for you to give to others.
  - `!leaderboard [channel] [timeframe]` - displays the leader board for a specified `channel` over the specified `timeframe`.  Channel must start with `#` or be `GLOBAL` (aggregated over all channels), and time frame must be in `[day, week, month, year, century]`.  Both `channel` and `timeframe` are optional, defaulting to `GLOBAL` and `century` respectively.
  - `!help` - displays help message that summarizes the available commands.      
