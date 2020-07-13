require 'date'
require 'logger'
require 'sqlite3'

logger = Logger.new($stdout)

while true
  sleep 60
  time = DateTime.now()
  if time.minute == 0 and time.hour == 0
    begin
      db = SQLite3::Database.open "db"
      db.execute "update tacos set amount = 10;"
      logger.info "Taco Quotas Reset"
    rescue
      logger.error "No Database Found When Attempting to Reset Taco Quotas"
    end
  end
end
