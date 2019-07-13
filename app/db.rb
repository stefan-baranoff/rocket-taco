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
      Db.ensureDatumExists db, "settings", "key", "server", ["'server'", "'localhost'"]
      Db.ensureDatumExists db, "settings", "key", "port", ["'port'", "'3000'"]
      Db.ensureDatumExists db, "settings", "key", "username", ["'username'", "'rocket_chat'"]
      Db.ensureDatumExists db, "settings", "key", "password", ["'password'", "'taco'"]
      Db.ensureTableExists db, "tacos", ['user', 'amount'], ['string', 'int']
      for chan in channels
        Db.ensureTableExists db, chan[0], ['time', 'giver', 'receiver', 'amount', 'reason'], ['real', 'string', 'string', 'int', 'string']
      end
      db
  end

  def Db.insertTaco db, chan, giver, receiver, quant, reason
    Db.ensureDatumExists db, "tacos", "user", giver, ["'#{giver}'", 5]
    tacos_left = db.execute("select amount from tacos where user = '#{giver}'")[0][0]
    if tacos_left >= quant * receiver.length
      for recv in receiver
        db.execute "insert into #{chan} values (julianday('now'), '#{giver}', '#{recv}', #{quant}, '#{reason}');"
      end
      db.execute "update tacos set amount = #{tacos_left - quant * receiver.length} where user = '#{giver}'"
      return true
    end
    false
  end

end
