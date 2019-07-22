require 'date'
require 'sqlite3'

module Db

  def Db.open
    db = nil
    begin
      db = SQLite3::Database.open "db"
    rescue
      begin
        db = SQLite3::Database.new "db"
      rescue
        puts "Unable to Initialize Database"
        exit 2
      end
    end
    db
  end

  def Db.ensureTableExists db, name, columns, types
    values = []
    for col in 0..(columns.length-1)
      values.push columns[col]+" "+types[col]
    end
    db.execute "create table if not exists #{name} (#{values.join(", ")});"
  end

  def Db.ensureDatumExists db, table, col, value, datas
    rows = db.execute "select * from #{table} where #{col} = '#{value}'"
    if rows.length == 0
      db.execute "insert into #{table} values (#{datas.join(', ')})"
    end
  end

  def Db.init channels
      db = Db.open
      Db.ensureTableExists db, "settings", ["key", "value"], ["string", "string"]
      Db.ensureDatumExists db, "settings", "key", "host", ["'host'", "'localhost'"]
      Db.ensureDatumExists db, "settings", "key", "host_port", ["'host_port'", "'4567'"]
      Db.ensureDatumExists db, "settings", "key", "server", ["'server'", "'localhost'"]
      Db.ensureDatumExists db, "settings", "key", "port", ["'port'", "'3000'"]
      Db.ensureDatumExists db, "settings", "key", "username", ["'username'", "'rocket_taco'"]
      Db.ensureDatumExists db, "settings", "key", "password", ["'password'", "'taco'"]
      Db.ensureTableExists db, "tacos", ['user', 'amount'], ['string', 'int']
      Db.ensureTableExists db, "GLOBAL", ['time', 'giver', 'receiver', 'amount', 'reason'], ['real', 'string', 'string', 'int', 'string']
      for chan in channels
        Db.ensureTableExists db, chan[0], ['time', 'giver', 'receiver', 'amount', 'reason'], ['real', 'string', 'string', 'int', 'string']
      end
      db
  end

  def Db.loadSettings db
    settings = {}
    for setting in db.execute "select * from settings"
      settings[setting[0]] = setting[1]
    end
    [settings["host"],settings["host_port"].to_i(),settings["server"],settings["port"].to_i(),settings["username"],settings["password"]]
  end

  def Db.saveSettings db, host, host_port, server, port, user, password
    db.execute "update settings set value = '#{host}' where key = 'host'"
    db.execute "update settings set value = '#{host_port}' where key = 'host_port'"
    db.execute "update settings set value = '#{server}' where key = 'server'"
    db.execute "update settings set value = '#{port}' where key = 'port'"
    db.execute "update settings set value = '#{user}' where key = 'user'"
    db.execute "update settings set value = '#{password}' where key = 'password'"
  end

  def Db.insertTaco db, chan, giver, receiver, quant, reason
    Db.ensureDatumExists db, "tacos", "user", giver, ["'#{giver}'", 5]
    tacos_left = db.execute("select amount from tacos where user = '#{giver}'")[0][0]
    if tacos_left >= quant * receiver.length
      for recv in receiver
        db.execute "insert into #{chan} values (julianday('now'), '#{giver}', '#{recv}', #{quant}, '#{reason}');"
        db.execute "insert into GLOBAL values (julianday('now'), '#{giver}', '#{recv}', #{quant}, '#{reason}');"
      end
      db.execute "update tacos set amount = #{tacos_left - quant * receiver.length} where user = '#{giver}'"
      return true
    end
    false
  end

  def Db.getTacos db, user
    Db.ensureDatumExists db, "tacos", "user", user, ["'#{user}'", 5]
    db.execute("select amount from tacos where user = '#{user}'")[0][0]
  end

  $leaderboard_query = %q(
    select %{user_type}, sum(amount) as total
    from %{channel}
    where time > %{oldest_date}
    group by %{user_type}
    order by total desc
    %{limit}
  )

  def Db.getLeaderBoard db, channel, timeframe, limit
    current_date = DateTime.now.amjd().to_f
    oldest_date = current_date - timeframe
    recv = db.execute(
      $leaderboard_query % {
        "user_type": "receiver",
        "channel": "'#{channel}'",
        "oldest_date": oldest_date,
        "limit":  limit ? "limit 10" : ""
      }
    )
    givers = db.execute(
      $leaderboard_query % {
        "user_type": "giver",
        "channel": "'#{channel}'",
        "oldest_date": oldest_date,
        "limit": limit ? "limit 10" : ""
      }
    )
    [recv, givers]
  end

  def Db.getUserStats db, channel, timeframe, user, type
    current_date = DateTime.now.amjd().to_f
    oldest_date = current_date - timeframe
    query = $leaderboard_query % {
      "user_type": "#{type}",
      "channel": "'#{channel}'",
      "oldest_date": oldest_date,
      "limit": ""
    }
    count = 1
    for row in db.execute query
      if row[0] == user
        return [count, row[1]]
      end
      count += 1
    end
    nil
  end

end
