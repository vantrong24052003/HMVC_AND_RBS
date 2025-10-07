Capistrano Deploy Notes (HMVC_AND_RBS)

1) Chuẩn bị thư mục shared trên server
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

2) Đặt file cấu hình bắt buộc
```bash
# Tạo/đặt các file cần thiết
# - /var/www/hmvc_and_rbs/shared/config/database.yml
# - /var/www/hmvc_and_rbs/shared/config/credentials/production.key
```

3) Cài công cụ hệ thống cần thiết
```bash
sudo apt update
sudo apt install -y git openssh-client
```

4) Cài RVM + Ruby + Bundler (user-level)
```bash
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 3.3.9
rvm use 3.3.9 --default
gem install bundler -v "~> 2.5"

# Kiểm tra bundler trong login shell (mô phỏng SSHKit)
env -i bash -lc 'source ~/.rvm/scripts/rvm && rvm use 3.3.9 >/dev/null && which bundle && bundle -v'
```

5) Các lệnh Capistrano hữu ích (chạy ở máy local)
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

6) Ghi chú & Mẹo Capistrano (cần nắm)

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

7) Checklist trước deploy

- [ ] Đã tạo đủ thư mục shared (mục 1).
- [ ] Đã đặt `database.yml` và `credentials/production.key` vào `shared/config` (mục 2).
- [ ] Server có Ruby, Bundler hoạt động trong login shell:
  ```bash
  env -i bash -lc 'source ~/.rvm/scripts/rvm && rvm use 3.3.9 >/dev/null && which bundle && bundle -v'
  ```
- [ ] `bundle exec cap production deploy:check` không báo thiếu file/dir.
- [ ] Nếu dùng RVM với Capistrano: trong repo có `require "capistrano/rvm"` và `set :rvm_ruby_version, "ruby-3.3.9"`.
