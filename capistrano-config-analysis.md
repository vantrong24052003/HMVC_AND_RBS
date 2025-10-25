# Capistrano Configuration Analysis - HMVC_AND_RBS

## Puma systemd unit (staging) – nội dung và giải thích daemon

### Unit file
```ini
[Unit]
Description=Puma HMVC_AND_RBS staging
After=network.target

[Service]
Type=simple
User=trong.doan
Group=trong.doan
WorkingDirectory=/var/www/hmvc_and_rbs/current
Environment=RAILS_ENV=staging
ExecStart=/bin/bash -lc '~/.rvm/bin/rvm 3.3.8 do bundle exec puma -C config/puma.rb'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Daemon là gì và cơ chế systemd
- Daemon: tiến trình nền chạy lâu dài, không gắn với terminal, khởi động cùng hệ thống và tự khôi phục khi lỗi.
- systemd: trình quản lý dịch vụ của Linux. Với file unit trên:
  - `[Unit]` định nghĩa phụ thuộc và mô tả dịch vụ.
  - `[Service]` chỉ cách khởi động tiến trình (lệnh, user, thư mục làm việc, biến môi trường, chính sách restart).
  - `[Install]` xác định target để auto-start khi boot (`multi-user.target`).
- Quy trình vận hành:
  - `systemctl daemon-reload`: nạp lại cấu hình dịch vụ.
  - `systemctl enable --now puma-hmvc-staging.service`: bật auto-start và chạy ngay.
  - `systemctl status ...`/`journalctl -u ...`: xem trạng thái và log.

## Tổng quan
File `config/deploy.rb` đã được cấu hình khá hoàn chỉnh cho Rails 8 application với HMVC architecture. Đây là phân tích chi tiết từng setting và lý do config.

## Phân tích từng setting

### 1. **Capistrano Version Lock**
```ruby
lock "~> 3.19.2"
```
**Lý do**: Đảm bảo tất cả team members sử dụng cùng version Capistrano, tránh conflicts và bugs từ version khác nhau.

### 2. **Application Configuration**
```ruby
set :application, "hmvc_and_rbs"
set :repo_url, "git@github.com:vantrong24052003/HMVC_AND_RBS.git"
set :deploy_to, "/var/www/hmvc_and_rbs"
```
**Lý do**:
- `application`: Tên app để Capistrano tạo directories và services
- `repo_url`: GitHub repository với SSH key authentication
- `deploy_to`: Standard path `/var/www/` cho web applications

### 3. **Linked Files & Directories**
```ruby
set :linked_files, -> { [".env", ".env.#{fetch(:rails_env)}"] }
set :linked_dirs, fetch(:linked_dirs, []).push("log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/flags", "public/tmp", "node_modules", "credentials", "public/packs")
```

**Lý do từng file/directory**:

#### Linked Files:
- `.env` & `.env.#{rails_env}`: Environment variables không được commit vào git
- `credentials`: Rails credentials files (production.key, etc.)

#### Linked Directories:
- `log`: Application logs cần persist qua các releases
- `tmp/pids`: Process IDs cho background jobs
- `tmp/cache`: Rails cache files
- `tmp/sockets`: Unix sockets cho Puma
- `tmp/flags`: Flag files cho deployment status
- `public/tmp`: Temporary uploaded files
- `node_modules`: Node.js dependencies (không commit vào git)
- `public/packs`: Vite compiled assets

### 4. **Git Configuration**
```ruby
set :branch, ENV.fetch("BRANCH", "main")
set :pty, false
```
**Lý do**:
- `branch`: Cho phép deploy từ branch khác qua environment variable
- `pty: false`: Disable pseudo-terminal, tránh issues với RVM/SSH

### 5. **Ruby Version Management (RVM)**
```ruby
set :rvm_ruby_version, File.read(".ruby-version").strip
set :rvm_type, :user
```
**Lý do**:
- Sử dụng RVM thay vì rbenv (tương thích với capistrano.md)
- Đọc version từ `.ruby-version` file (3.3.8)
- `:user` type cho user-level installation (không cần sudo)

### 6. **Node.js Version Management (nodenv)**
```ruby
set :nodenv_type, :system
set :nodenv_node, File.read(".node-version").strip
set :nodenv_map_bins, %w[node npm yarn]
```
**Lý do**:
- Quản lý Node.js version cho Vite build process
- Map binaries để Capistrano có thể chạy node/npm/yarn commands
- **⚠️ ISSUE**: Không có `.node-version` file trong project

### 7. **Yarn Configuration**
```ruby
set :yarn_target_path, -> { release_path }
```
**Lý do**: Yarn install trong release directory, không trong shared

### 8. **Assets Precompilation**
```ruby
set :assets_roles, %i[web batch]
```
**Lý do**:
- `web`: Serve static assets
- `batch`: Background processing cho assets

### 9. **Whenever (Cron Jobs)**
```ruby
set :whenever_environment, -> { fetch(:rails_env) }
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
set :whenever_roles, -> { %i[app] }
set :whenever_path, -> { release_path }
set :whenever_load_file, -> { File.join(release_path, "config", "schedules", "#{fetch(:stage)}.rb") }
```
**Lý do**:
- Environment-specific cron jobs
- Unique identifier cho mỗi stage
- Load schedule files từ `config/schedules/`

### 10. **Database Migrations**
```ruby
set :migration_command, "RAILS_ENV=#{fetch(:rails_env)} bundle exec rails db:migrate"
```
**Lý do**: Explicit RAILS_ENV để đảm bảo migrations chạy đúng environment

## Staging Configuration

### **File: `config/deploy/staging.rb`**

```ruby
# frozen_string_literal: true

# Stage and Environment Configuration
set :stage, :staging
set :rails_env, "staging"

# Server Configuration
server "34.55.113.241",
  user: "deploy",
  roles: %w{app db web},
  ssh_options: {
    keys: %w(/home/vantrong/.ssh/id_rsa),
    forward_agent: false,
    auth_methods: %w(publickey)
  }
```

### **Giải thích từng dòng (Non-tech)**

#### **`# frozen_string_literal: true`**
- **Frozen string** = "Đóng băng chuỗi"
- **Lý do**: Ruby không cho phép sửa đổi string literals
- **Lợi ích**: Tăng performance, tránh lỗi

#### **Stage và Environment Configuration**

**`set :stage, :staging`**
- **Stage** = "Giai đoạn deployment"
- **`:staging`** = Môi trường staging
- **Lý do**: Capistrano biết đang deploy lên staging

**`set :rails_env, "staging"`**
- **Rails environment** = "Môi trường Rails"
- **"staging"** = Rails sẽ chạy trong staging mode
- **Lý do**: Rails app biết đang ở môi trường nào

#### **Server Configuration**

**`server "34.55.113.241"`**
- **Server** = "Máy chủ đích"
- **"34.55.113.241"** = IP address của VPS
- **Lý do**: Capistrano biết deploy lên server nào

**`user: "deploy"`**
- **User** = "Tên user SSH"
- **"deploy"** = User để kết nối và deploy
- **Lý do**: Capistrano dùng user này để SSH vào server

**`roles: %w{app db web}`**
- **Roles** = "Vai trò của server"
- **`app`** = Server chạy Rails application
- **`db`** = Server chạy database (PostgreSQL)
- **`web`** = Server chạy web server (Nginx)
- **Lý do**: Capistrano biết server đảm nhận vai trò gì

#### **SSH Options**

**`keys: %w(/home/vantrong/.ssh/id_rsa)`**
- **Keys** = "Khóa SSH"
- **Path** = Đường dẫn đến SSH private key
- **Lý do**: Capistrano dùng key này để authenticate

**`forward_agent: false`**
- **Forward agent** = "Chuyển tiếp SSH agent"
- **false** = Không chuyển tiếp
- **Lý do**: Không cần forward SSH agent cho deployment

**`auth_methods: %w(publickey)`**
- **Auth methods** = "Phương thức xác thực"
- **publickey** = Chỉ dùng SSH key, không dùng password
- **Lý do**: Bảo mật hơn, không cần nhập password

### **Tóm lại Staging Config**

#### **Mục đích của config:**
- **Stage**: Định nghĩa môi trường staging
- **Server**: Kết nối đến VPS 34.55.113.241
- **User**: Dùng user "deploy" để SSH
- **Roles**: Server đảm nhận app, db, web
- **SSH**: Dùng key authentication, không password

#### **Ví dụ thực tế:**
Giống như **đặt địa chỉ nhà** và **chìa khóa** để Capistrano có thể vào deploy!

- **Địa chỉ nhà** = `34.55.113.241`
- **Chìa khóa** = SSH key `/home/vantrong/.ssh/id_rsa`
- **Người vào** = User `deploy`
- **Vai trò** = App, Database, Web server

#### **Next Steps:**
1. **Tạo user `deploy`** trên VPS
2. **Setup SSH key** cho user deploy
3. **Test connection**: `ssh deploy@34.55.113.241`
4. **Deploy**: `bundle exec cap staging deploy`
