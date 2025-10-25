lock "~> 3.19.2"

set :application, "hmvc_and_rbs"
set :repo_url, "git@github.com:vantrong24052003/HMVC_AND_RBS.git"
set :deploy_to, "/var/www/hmvc_and_rbs"

# Link files and directories
set :linked_files, -> { [".env", ".env.#{fetch(:rails_env)}"] }
set :linked_dirs, fetch(:linked_dirs, []).push("log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/flags", "public/tmp", "node_modules", "credentials", "public/packs")

set :branch, ENV.fetch("BRANCH", "main")

# Pseudo-terminal (disable)
# Khi deploy bằng Capistrano, có thể hiểu như nhờ một “con bot” SSH vào server để chạy lệnh thay mình.
# Nếu set :pty, true → Capistrano sẽ mở một terminal giả (pseudo-terminal).
#   - Khi lệnh yêu cầu quyền sudo (ví dụ: sudo systemctl restart nginx),
#     terminal giả này sẽ đợi nhập mật khẩu nhưng không có ai nhập → gây lỗi hoặc dừng deploy.
# Nếu set :pty, false → Capistrano sẽ chạy lệnh trực tiếp qua SSH, không cần mở terminal giả,
# giúp quá trình deploy diễn ra tự động, không bị gián đoạn.
set :pty, false

# RVM
set :rvm_type, :system
set :rvm_ruby_version, File.read(".ruby-version").strip

# nodenv
set :nodenv_type, :system
set :nodenv_node, File.read(".node-version").strip
set :nodenv_map_bins, %w[node npm yarn]

# yarn
set :yarn_target_path, -> { release_path }

# assets:precompile
set :assets_roles, %i[web batch]

# whenever
set :whenever_environment, -> { fetch(:rails_env) }
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
set :whenever_roles, -> { %i[app] }
set :whenever_path, -> { release_path }
set :whenever_load_file, -> { File.join(release_path, "config", "schedules", "#{fetch(:stage)}.rb") }

set :migration_command, "RAILS_ENV=#{fetch(:rails_env)} bundle exec rails db:migrate"
