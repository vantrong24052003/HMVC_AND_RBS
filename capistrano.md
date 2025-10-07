# Capistrano Deploy Notes (HMVC_AND_RBS)

## Mục lục

### Phần 1: Capistrano Setup & Deploy
- [1. Chuẩn bị thư mục shared trên server](#1-chuẩn-bị-thư-mục-shared-trên-server)
- [2. Đặt file cấu hình bắt buộc](#2-đặt-file-cấu-hình-bắt-buộc)
- [3. Cài công cụ hệ thống cần thiết](#3-cài-công-cụ-hệ-thống-cần-thiết)
- [4. Cài RVM + Ruby + Bundler](#4-cài-rvm--ruby--bundler)
- [5. Các lệnh Capistrano hữu ích](#5-các-lệnh-capistrano-hữu-ích)
- [6. Ghi chú & Mẹo Capistrano](#6-ghi-chú--mẹo-capistrano)
- [7. Checklist trước deploy](#7-checklist-trước-deploy)

### Phần 2: Rails 500 Error Debug
- [Tổng quan](#tổng-quan)
- [Nguyên nhân thường gặp](#nguyên-nhân-thường-gặp)
- [Checklist Debug (9 bước)](#checklist-debug-thứ-tự-ưu-tiên)
- [Local Debug Commands](#local-debug-commands)
- [Common Fixes](#common-fixes)
- [Quick Diagnostic Commands](#quick-diagnostic-commands)
- [Prevention Tips](#prevention-tips)
- [Troubleshooting Flow](#troubleshooting-flow)
- [Notes](#notes)

---

## 1. Chuẩn bị thư mục shared trên server
```bash
sudo mkdir -p \
  /var/www/hmvc_and_rbs/shared/config/credentials \
  /var/www/hmvc_and_rbs/shared/log \
  /var/www/hmvc_and_rbs/shared/tmp/pids \
  /var/www/hmvc_and_rbs/shared/tmp/cache \
  /var/www/hmvc_and_rbs/shared/tmp/sockets \
  /var/www/hmvc_and_rbs/shared/storage
sudo chown -R trong.doan: /var/www/hmvc_and_rbs

# Kiểm tra cấu trúc
ls -la /var/www/hmvc_and_rbs/shared/config
```

## 2. Đặt file cấu hình bắt buộc
```bash
# Tạo/đặt các file cần thiết
# - /var/www/hmvc_and_rbs/shared/config/database.yml
# - /var/www/hmvc_and_rbs/shared/config/credentials/production.key
```

## 3. Cài công cụ hệ thống cần thiết
```bash
sudo apt update
sudo apt install -y git openssh-client
```

## 4. Cài RVM + Ruby + Bundler (user-level)
```bash
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 3.3.9
rvm use 3.3.9 --default
gem install bundler -v "~> 2.5"

# Kiểm tra bundler trong login shell (mô phỏng SSHKit)
env -i bash -lc 'source ~/.rvm/scripts/rvm && rvm use 3.3.9 >/dev/null && which bundle && bundle -v'
```

## 5. Các lệnh Capistrano hữu ích (chạy ở máy local)
```bash
# Liệt kê tasks
bundle exec cap -T

# Kiểm tra server cấu hình
bundle exec cap production doctor:servers

# Kiểm tra điều kiện deploy
bundle exec cap production deploy:check

# Triển khai
bundle exec cap production deploy
```

## 6. Ghi chú & Mẹo Capistrano (cần nắm)

- linked_files là gì
  - Các file nhạy cảm/khác nhau theo môi trường không được copy vào từng release, mà tạo symlink từ `shared`.
  - Nếu file chưa tồn tại trong `shared`, deploy sẽ fail.
  - Ví dụ trong dự án này:
    - `config/credentials/production.key` ↔ `/var/www/hmvc_and_rbs/shared/config/credentials/production.key`
    - `config/database.yml` ↔ `/var/www/hmvc_and_rbs/shared/config/database.yml`

- linked_dirs là gì
  - Các thư mục cần giữ dữ liệu qua nhiều release (log, tmp, storage, vendor...).
  - Cũng là symlink từ `release_path/<dir>` sang `shared/<dir>`.

- release_path vs current_path
  - Mỗi lần deploy tạo một thư mục mới dưới `releases/<timestamp>` → đó là `release_path`.
  - `current` là symlink trỏ tới release mới nhất → web server/app server nên trỏ vào `current`.

- Cách tự kiểm tra nhanh trên server
  - Kiểm tra file trong shared:
    ```bash
    ls -l /var/www/hmvc_and_rbs/shared/config/credentials/production.key
    ls -l /var/www/hmvc_and_rbs/shared/config/database.yml
    ```
  - Kiểm tra symlink trong current:
    ```bash
    ls -l /var/www/hmvc_and_rbs/current/config/credentials/production.key
    ls -l /var/www/hmvc_and_rbs/current/config/database.yml
    ```

## 7. Checklist trước deploy

- [ ] Đã tạo đủ thư mục shared (mục 1).
- [ ] Đã đặt `database.yml` và `credentials/production.key` vào `shared/config` (mục 2).
- [ ] Server có Ruby, Bundler hoạt động trong login shell:
  ```bash
  env -i bash -lc 'source ~/.rvm/scripts/rvm && rvm use 3.3.9 >/dev/null && which bundle && bundle -v'
  ```
- [ ] `bundle exec cap production deploy:check` không báo thiếu file/dir.
- [ ] Nếu dùng RVM với Capistrano: trong repo có `require "capistrano/rvm"` và `set :rvm_ruby_version, "ruby-3.3.9"`.

---

# Rails 500 Error Debug Tips

## Tổng quan
Khi gặp lỗi 500 Internal Server Error sau khi deploy Rails app với Capistrano, đây là checklist đầy đủ để debug và fix.

## Nguyên nhân thường gặp
1. **ViteRuby::MissingEntrypointError** - Chưa build frontend assets
2. **Database connection error** - Database không accessible
3. **File permissions** - Không có quyền đọc/ghi files
4. **Nginx config sai** - Web server không proxy đúng
5. **Missing environment variables** - Thiếu config files
6. **Services không chạy** - Nginx, PostgreSQL, Puma down
7. **502 Bad Gateway** - Nginx không kết nối được Puma
8. **422 Unprocessable Entity** - CSRF token hoặc SSL mismatch

---

## Checklist Debug (Thứ tự ưu tiên)

### 1. Rails Production Logs ⭐ (QUAN TRỌNG NHẤT)
```bash
# SSH vào server
ssh trong.doan@34.55.113.241

# Xem Rails logs real-time
tail -f /var/www/hmvc_and_rbs/current/log/production.log
```
**Lý do**: Rails logs sẽ hiển thị chi tiết lỗi, stack trace, và nguyên nhân gây ra 500 error.

### 2. Puma Application Server Logs
```bash
# Xem Puma logs
tail -f /var/www/hmvc_and_rbs/current/log/puma.log

# Kiểm tra Puma process
ps aux | grep puma

# Kiểm tra Puma status
sudo systemctl status puma
```
**Lý do**: Application server logs cho biết Rails app có chạy được không.

### 3. Database Connection Test
```bash
# Vào project directory
cd /var/www/hmvc_and_rbs/current

# Test database connection
RAILS_ENV=production bundle exec rails console

# Trong Rails console, test database
ActiveRecord::Base.connection.execute("SELECT 1")
```
**Lý do**: Database connection là nguyên nhân phổ biến gây 500 error.

### 4. Asset Compilation (Vite Build)
```bash
# Vào project directory
cd /var/www/hmvc_and_rbs/current

# Cài dependencies (nếu cần)
yarn install

# Build assets cho production
RAILS_ENV=production bundle exec rails assets:precompile

# Hoặc dùng Vite trực tiếp
bin/vite build --clear --mode=production

# Restart Puma sau khi build
sudo systemctl restart puma
```
**Lý do**: Rails production cần precompiled assets để serve static files.

### 5. Nginx Configuration Check
```bash
# Kiểm tra nginx config
sudo cat /etc/nginx/sites-available/default

# Test nginx config
sudo nginx -t

# Reload nginx nếu cần
sudo systemctl reload nginx
```
**Lý do**: Nginx cần proxy đúng đến Puma port và đúng path.

### 6. File Permissions Check
```bash
# Kiểm tra quyền của current symlink
ls -la /var/www/hmvc_and_rbs/current

# Kiểm tra quyền của shared files
ls -la /var/www/hmvc_and_rbs/shared/config/

# Kiểm tra quyền của log directory
ls -la /var/www/hmvc_and_rbs/current/log/
```
**Lý do**: Permission issues có thể ngăn Rails đọc config files hoặc write logs.

### 7. Environment Variables & Config Files
```bash
# Kiểm tra RAILS_ENV
echo $RAILS_ENV

# Kiểm tra database config
cat /var/www/hmvc_and_rbs/shared/config/database.yml

# Kiểm tra credentials
ls -la /var/www/hmvc_and_rbs/shared/config/credentials/
```
**Lý do**: Missing environment variables hoặc config files có thể gây lỗi.

### 8. Services Status Check
```bash
# Kiểm tra tất cả services
sudo systemctl status nginx
sudo systemctl status postgresql
sudo systemctl status puma

# Kiểm tra disk space
df -h

# Kiểm tra memory
free -h
```
**Lý do**: Services phải chạy để app hoạt động.

### 9. Nginx Logs
```bash
# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log
```
**Lý do**: Web server logs cho biết có request nào đến server không và lỗi gì ở tầng web server.

---

## Local Debug Commands

### 1. Capistrano Deployment Logs
```bash
# Xem log của lần deploy cuối
cat log/capistrano.log

# Deploy lại với verbose output
bundle exec cap production deploy --trace
```
**Lý do**: Capistrano logs cho biết có step nào fail trong quá trình deploy.

### 2. Test Production Locally
```bash
# Trong project directory
RAILS_ENV=production bundle exec rails console

# Test connection
ActiveRecord::Base.connection.execute("SELECT 1")
```
**Lý do**: Xác định database có accessible từ local không.

---

## Common Fixes

### 1. Fix ViteRuby::MissingEntrypointError
```bash
# Cài Node.js và Yarn (nếu chưa có)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g yarn

# Build assets
cd /var/www/hmvc_and_rbs/current
yarn install
RAILS_ENV=production bundle exec rails assets:precompile
sudo systemctl restart puma
```

### 2. Fix Database Connection Error
```bash
# Kiểm tra PostgreSQL service
sudo systemctl status postgresql

# Restart PostgreSQL nếu cần
sudo systemctl restart postgresql
```

### 3. Fix Missing Credentials
```bash
# Kiểm tra credentials file
ls -la /var/www/hmvc_and_rbs/shared/config/credentials/production.key

# Nếu thiếu, copy từ local
scp config/credentials/production.key trong.doan@34.55.113.241:/var/www/hmvc_and_rbs/shared/config/credentials/
```

### 4. Fix Nginx Config
```bash
# Backup config hiện tại
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Sửa config với đúng path
sudo nano /etc/nginx/sites-available/default

# Nội dung config đúng:
upstream puma {
  server 127.0.0.1:4000;
}

server {
  listen 80;
  server_name _;

  root /var/www/hmvc_and_rbs/current/public;
  access_log /var/www/hmvc_and_rbs/shared/log/nginx.access.log;
  error_log /var/www/hmvc_and_rbs/shared/log/nginx.error.log;

  location / {
    proxy_pass http://puma;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Ssl off;  # ✅ ĐÚNG (vì không có SSL)
    proxy_redirect off;
  }

  error_page 500 502 503 504 /500.html;
  client_max_body_size 10M;
  keepalive_timeout 10;
}

# Test và reload
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Fix 502 Bad Gateway
```bash
# Kiểm tra Puma có chạy không
sudo systemctl status puma
ps aux | grep puma

# Kiểm tra Puma logs
tail -f /var/www/hmvc_and_rbs/current/log/puma.log

# Test Puma trực tiếp
curl -I http://127.0.0.1:4000

# Kiểm tra nginx error logs
sudo tail -f /var/log/nginx/error.log

# Restart Puma nếu cần
sudo systemctl restart puma

# Restart nginx nếu cần
sudo systemctl restart nginx

# Kiểm tra port conflict
sudo lsof -i :4000
```

### 6. Fix 422 Unprocessable Entity
```bash
# Kiểm tra Rails SSL config
cd /var/www/hmvc_and_rbs/current
RAILS_ENV=production bundle exec rails console

# Trong Rails console:
Rails.application.config.force_ssl
Rails.application.config.assume_ssl

# Disable SSL tạm thời nếu cần
sudo nano config/environments/production.rb
# Sửa: config.force_ssl = false
# Sửa: config.assume_ssl = false

# Restart Puma
sudo systemctl restart puma
```

### 7. Fix 500 khi tạo todos (Turbo Stream)
```bash
# Kiểm tra Todo model
cat /var/www/hmvc_and_rbs/current/app/models/todo.rb

# Comment out Turbo Stream callbacks
sudo nano /var/www/hmvc_and_rbs/current/app/models/todo.rb

# Comment out các dòng cuối:
# after_create_commit -> { broadcast_append_to :todos, target: "todos" }
# after_update_commit -> { broadcast_replace_to :todos }
# after_destroy_commit -> { broadcast_remove_to :todos }

# Restart Puma
sudo systemctl restart puma

# Test tạo todo
RAILS_ENV=production bundle exec rails console
todo = Todo.new(title: "Test", description: "Test")
todo.save
```

---

## Quick Diagnostic Commands

```bash
# Kiểm tra tất cả services
sudo systemctl status nginx postgresql puma

# Kiểm tra disk space
df -h

# Kiểm tra memory
free -h

# Kiểm tra network
curl -I http://localhost:3000

# Kiểm tra Puma port
curl -I http://localhost:4000
```

---

## Troubleshooting Flow

1. **Check Rails logs first** → Tìm nguyên nhân chính xác
2. **Check Puma logs** → Xác nhận application server
3. **Test database** → Kiểm tra connection
4. **Build assets** → Fix Vite issues
5. **Check nginx config** → Fix web server
6. **Verify permissions** → Fix file access
7. **Check services** → Ensure all running
8. **Fix 502 errors** → Restart nginx/Puma
9. **Fix 422 errors** → Check SSL/CSRF config

---

## Notes
- Luôn bắt đầu với Rails production logs
- ViteRuby errors thường do chưa build assets
- Nginx config phải match với project path
- Database connection là nguyên nhân phổ biến nhất
- File permissions cần đúng cho user deploy
- **502 Bad Gateway**: Thường do Puma restart, cần restart nginx
- **422 Unprocessable Entity**: Thường do SSL/CSRF mismatch
- **Nginx path sai**: `/var/www/my_app/` → `/var/www/hmvc_and_rbs/`
- **SSL config**: `X-Forwarded-Ssl off` khi không có SSL
- **500 khi tạo todos**: Do Turbo Stream callbacks, comment out `broadcast_*` methods
- **Turbo Stream errors**: `No unique index found for id` từ `broadcast_append_to`

---

## Phần 3: Hotfix cập nhật code thủ công (scp + restart)

### Khi nào dùng
- Cần sửa nhanh một vài file view/model/config mà chưa muốn chạy deploy full Capistrano
- Không thay đổi dependencies, migrations, assets

### Bước 1: Chuẩn bị trên máy local
```bash
cd /home/vantrong/Documents/HMVC_AND_RBS
# Chỉnh sửa file cần hotfix, ví dụ:
# - app/views/todos/index.html.erb
# - app/models/todo.rb
# - config/environments/production.rb
```

### Bước 2: Copy file lên server bằng scp
```bash
# Ví dụ copy 1 file view
scp app/views/todos/index.html.erb \
  trong.doan@34.55.113.241:/var/www/hmvc_and_rbs/current/app/views/todos/index.html.erb

# Ví dụ copy model
scp app/models/todo.rb \
  trong.doan@34.55.113.241:/var/www/hmvc_and_rbs/current/app/models/todo.rb

# Ví dụ copy config production
scp config/environments/production.rb \
  trong.doan@34.55.113.241:/var/www/hmvc_and_rbs/current/config/environments/production.rb
```

Lưu ý:
- Luôn `cd` đúng thư mục project local trước khi scp để tránh lỗi `No such file or directory`
- Đường dẫn đích trên server phải nằm trong `current/`

### Bước 3: Restart services
```bash
ssh trong.doan@34.55.113.241
sudo systemctl restart puma
# Reload nginx nếu có sửa reverse proxy
sudo systemctl reload nginx
```

### Bước 4: Kiểm tra nhanh
```bash
# Test qua nginx (từ server hoặc local)
curl -I http://34.55.113.241/

# Test trực tiếp Puma
curl -I http://127.0.0.1:4000/
```

### Bước 5: Theo dõi logs realtime
```bash
tail -f \
  /var/www/hmvc_and_rbs/current/log/production.log \
  /var/www/hmvc_and_rbs/current/log/puma.log \
  /var/log/nginx/error.log \
  /var/log/nginx/access.log
```

### Bước 6: Dọn dữ liệu nếu bỏ nil-safe enums (tùy chọn)
Trong trường hợp bỏ nil-safe ở view cho các enum `priority`, `status`, cần đảm bảo database không còn bản ghi nil:
```bash
cd /var/www/hmvc_and_rbs/current
RAILS_ENV=production bundle exec rails console

Todo.where(priority: nil).update_all(priority: 0)
Todo.where(status: nil).update_all(status: 0)
```

### Bước 7: Rollback nhanh (nếu cần)
```bash
# Nếu đã backup file trước khi scp, scp ngược file backup lên lại vị trí cũ rồi restart puma
# Hoặc deploy lại release gần nhất bằng Capistrano để quay về trạng thái ổn định
```

### Checklist hotfix
- [ ] File local đã chỉnh đúng
- [ ] scp đúng đường dẫn `current/` trên server
- [ ] Restart Puma thành công
- [ ] Nginx proxy 200 OK
- [ ] Logs không còn lỗi mới phát sinh

---

## Phần 4: Systemd env và Sidekiq/Puma services (chuẩn production)

### 1) Tạo file env dùng chung (không cần sửa code)
```bash
sudo tee /var/www/hmvc_and_rbs/shared/env >/dev/null <<'EOF'
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/ZZZ
EOF
sudo chmod 600 /var/www/hmvc_and_rbs/shared/env
```

### 2) Puma — thêm drop-in override để nạp env và ép RAILS_ENV=production
```bash
sudo mkdir -p /etc/systemd/system/puma.service.d
sudo tee /etc/systemd/system/puma.service.d/override.conf >/dev/null <<'EOF'
[Service]
Environment=RAILS_ENV=production
EnvironmentFile=/var/www/hmvc_and_rbs/shared/env
EOF

sudo systemctl daemon-reload
sudo systemctl restart puma
```

### 3) Sidekiq — drop-in override và reset ExecStart để dùng RVM
```bash
sudo mkdir -p /etc/systemd/system/sidekiq.service.d
sudo tee /etc/systemd/system/sidekiq.service.d/override.conf >/dev/null <<'EOF'
[Service]
Environment=RAILS_ENV=production
EnvironmentFile=/var/www/hmvc_and_rbs/shared/env
WorkingDirectory=/var/www/hmvc_and_rbs/current
User=trong.doan
ExecStart=
ExecStart=/home/trong.doan/.rvm/bin/rvm 3.3.8 do bundle exec sidekiq -e production -c 5 -q default -q mailers
EOF

sudo systemctl daemon-reload
sudo systemctl restart sidekiq
```

### 4) Kiểm tra nhanh
```bash
# Xem file env đã được nạp bởi systemd
systemctl show puma -p EnvironmentFiles
systemctl show sidekiq -p EnvironmentFiles

# Kiểm tra biến môi trường trong tiến trình đang chạy
pid=$(systemctl show -p MainPID --value puma); tr '\0' '\n' </proc/$pid/environ | grep -E 'RAILS_ENV|SLACK_WEBHOOK_URL'
pid=$(systemctl show -p MainPID --value sidekiq); tr '\0' '\n' </proc/$pid/environ | grep -E 'RAILS_ENV|SLACK_WEBHOOK_URL'

# App và worker
curl -I http://127.0.0.1:4000
sudo systemctl status sidekiq --no-pager
```

### 5) Lỗi thường gặp & cách xử lý
- `502` và log Puma hiển thị `Environment: development`: thiếu `Environment=RAILS_ENV=production` trong drop-in Puma.
- `'/usr/bin/env: bundle: No such file or directory'`: chưa reset `ExecStart` hoặc chưa dùng RVM trong Sidekiq → thêm `ExecStart=` rồi đặt lại `ExecStart=/home/trong.doan/.rvm/bin/rvm 3.3.8 do bundle exec sidekiq ...`.
- `EnvironmentFile` không nạp: kiểm tra quyền file, định dạng dòng `KEY=VALUE` (không `export`, không khoảng trắng), tránh CRLF (`dos2unix`).
- Trùng cấu hình: chỉ dùng drop-in `override.conf`; nếu đã sửa trực tiếp file unit, nên `sudo systemctl revert <service>` để sạch trước khi tạo drop-in.
