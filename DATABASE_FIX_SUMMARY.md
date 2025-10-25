# Database Connection Fix - Tóm Tắt

## 🔴 Vấn đề
```
ActiveRecord::ConnectionNotEstablished: connection to server at "127.0.0.1", port 5432 failed: fe_sendauth: no password supplied
```

## 🔍 Nguyên nhân chính
1. **PostgreSQL user `postgres` chưa có password**
2. **Migration command thiếu `RAILS_ENV=staging`**
3. **Database.yml dùng ENV variables nhưng không có giá trị**

## ✅ Cách Fix (4 bước)

### 1. Tạo PostgreSQL user và database
```bash
ssh trong.doan@34.55.113.241
sudo -u postgres psql

# Trong psql:
CREATE USER postgres_staging WITH PASSWORD 'staging' SUPERUSER;
CREATE DATABASE todos_staging OWNER postgres_staging;
\q

# Test:
psql -h localhost -U postgres_staging -d todos_staging
# Password: staging
```

### 2. Fix migration command
```ruby
# config/deploy/staging.rb
set :migration_command, "RAILS_ENV=staging db:migrate"
```

### 3. Hardcode database config
```yaml
# config/database.yml
staging:
  <<: *default
  database: todos_staging
  username: postgres_staging
  password: staging
  host: localhost
  port: 5432
```

### 4. Update file trên server
```bash
# Copy file database.yml lên server
scp config/database.yml trong.doan@34.55.113.241:/var/www/hmvc_and_rbs/shared/config/database.yml

# Hoặc edit trực tiếp
nano /var/www/hmvc_and_rbs/shared/config/database.yml
```

## 🎯 Kết quả
- ✅ Database connection thành công
- ✅ Migration chạy thành công
- ✅ Deploy staging hoàn thành

## 📝 Lưu ý
- **Staging**: Dùng hardcode config (đơn giản)
- **Production**: Nên dùng ENV variables (bảo mật)
- **User**: `postgres_staging` / **Password**: `staging` / **DB**: `todos_staging`
