# frozen_string_literal: true

set :output, "log/cron_development.log"

every "* * * * *" do
  rake "todos:dispatch:daily", environment: "development"
end

every "* * * * *" do
  rake "todos:dispatch:weekly", environment: "development"
end

every "* * * * *" do
  rake "todos:dispatch:monthly", environment: "development"
end
