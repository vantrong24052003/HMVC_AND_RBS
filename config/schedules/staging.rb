# frozen_string_literal: true

set :output, "log/cron_staging.log"

every "* * * * *" do
  rake "todos:dispatch:daily", environment: "staging"
end

every "* * * * *" do
  rake "todos:dispatch:weekly", environment: "staging"
end

every "* * * * *" do
  rake "todos:dispatch:monthly", environment: "staging"
end
