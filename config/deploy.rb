lock "~> 3.19.2"

set :application, "hmvc_and_rbs"
set :repo_url, "git@github.com:vantrong24052003/HMVC_AND_RBS.git"
set :branch, "main"

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/hmvc_and_rbs"

# Default value for :format is :airbrussh.
set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []

# Quy tắc Capistrano: mỗi item trong linked_files sẽ được tìm ở ${deploy_to}/shared/<path>.
# Nên file cần có ở: /var/www/hmvc_and_rbs/shared/config/credentials/production.key
# Tương tự: config/database.yml → /var/www/hmvc_and_rbs/shared/config/database.yml

append :linked_files, "config/database.yml", "config/credentials/production.key"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# RVM configuration
set :rvm_type, :user
set :rvm_ruby_version, "3.3.8"

# Default value for default_env is {}
set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
set :ssh_options, verify_host_key: :secure
