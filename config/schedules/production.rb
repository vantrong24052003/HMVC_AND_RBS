# frozen_string_literal: true

set :output, "log/cron_production.log"

every "* * * * *" do
  rake "todos:dispatch:daily", environment: "production"
end

every "* * * * *" do
  rake "todos:dispatch:weekly", environment: "production"
end

every "* * * * *" do
  rake "todos:dispatch:monthly", environment: "production"
end
