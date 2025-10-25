# 🔍 STAGING ERROR DEBUGGING GUIDE - Lỗi 500

## 🚨 **KHI GẶP LỖI 500 - CÁC BƯỚC CHECK LOG**

### **1. Kiểm tra Nginx Error Logs**
```bash
# Check Nginx error logs (thường chứa lỗi 500)
sudo tail -n 100 /var/log/nginx/error.log

# Check Nginx access logs để xem request nào gây lỗi
sudo tail -n 100 /var/log/nginx/access.log

# Check Nginx config có đúng không
sudo nginx -t

# Restart Nginx nếu cần
sudo systemctl restart nginx
```

### **2. Kiểm tra Rails Application Logs**
```bash
# Check Rails staging log (log chính của app)
tail -n 100 /var/www/hmvc_and_rbs/current/log/staging.log

# Check Rails log với grep để tìm lỗi cụ thể
grep -i 'error\|exception\|500' /var/www/hmvc_and_rbs/current/log/staging.log | tail -20

# Check log với timestamp gần đây
tail -100 /var/www/hmvc_and_rbs/current/log/staging.log | grep -E 'ERROR|FATAL|Exception'
```

### **3. Kiểm tra Puma Service Logs (Journalctl)**
```bash
# Check Puma systemd logs
sudo journalctl -u puma-hmvc-staging.service -n 100

# Check Puma logs với timestamp
sudo journalctl -u puma-hmvc-staging.service --since '1 hour ago'

# Check Puma logs với grep
sudo journalctl -u puma-hmvc-staging.service | grep -i 'error\|exception\|500'

# Check Puma status
sudo systemctl status puma-hmvc-staging.service
```

### **4. Kiểm tra Database Connection**
```bash
# Test database connection
cd /var/www/hmvc_and_rbs/current && RAILS_ENV=staging bundle exec rails runner 'puts ActiveRecord::Base.connection.execute("SELECT 1").first'

# Check database logs
sudo tail -n 100 /var/log/postgresql/postgresql-*.log

# Check PostgreSQL status
sudo systemctl status postgresql
```

### **5. Kiểm tra Environment Variables**
```bash
# Check .env files
ls -la /var/www/hmvc_and_rbs/shared/.env*
cat /var/www/hmvc_and_rbs/shared/.env.staging

# Check database.yml
cat /var/www/hmvc_and_rbs/shared/config/database.yml
```

### **6. Kiểm tra Dependencies & Gems**
```bash
# Check bundle install
cd /var/www/hmvc_and_rbs/current && bundle check

# Check missing gems
cd /var/www/hmvc_and_rbs/current && bundle install --deployment

# Check yarn dependencies
cd /var/www/hmvc_and_rbs/current && yarn check
```

### **7. Kiểm tra File Permissions**
```bash
# Check file permissions
ls -la /var/www/hmvc_and_rbs/current/
ls -la /var/www/hmvc_and_rbs/shared/

# Check log directory permissions
ls -la /var/www/hmvc_and_rbs/current/log/
ls -la /var/www/hmvc_and_rbs/shared/log/
```

### **8. Kiểm tra Memory & Resources**
```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check running processes
ps aux | grep -E 'puma|nginx|postgres'
```

### **9. Kiểm tra Rails Console**
```bash
# Test Rails console
cd /var/www/hmvc_and_rbs/current && RAILS_ENV=staging bundle exec rails console

# Trong Rails console, test:
# - ActiveRecord::Base.connection.execute("SELECT 1")
# - User.count
# - Rails.logger.info "Test log"
```

### **10. Kiểm tra Sidekiq (Background Jobs)**
```bash
# Check Sidekiq logs
tail -n 100 /var/www/hmvc_and_rbs/current/log/sidekiq.log

# Check Sidekiq processes
ps aux | grep sidekiq
```

## 🔧 **CÁC LỖI 500 THƯỜNG GẶP & CÁCH FIX**

### **1. Database Connection Error**
```bash
# Lỗi: ActiveRecord::ConnectionNotEstablished
# Fix: Restart PostgreSQL
sudo systemctl restart postgresql

# Check database config
cd /var/www/hmvc_and_rbs/current && RAILS_ENV=staging bundle exec rails db:migrate:status
```

### **2. Missing Environment Variables**
```bash
# Lỗi: Missing environment variables
# Fix: Check .env files
cat /var/www/hmvc_and_rbs/shared/.env.staging

# Restart Puma sau khi fix
sudo systemctl restart puma-hmvc-staging.service
```

### **3. Missing Dependencies**
```bash
# Lỗi: Missing gems
# Fix: Reinstall dependencies
cd /var/www/hmvc_and_rbs/current && bundle install --deployment
cd /var/www/hmvc_and_rbs/current && yarn install
```

### **4. File Permission Issues**
```bash
# Lỗi: Permission denied
# Fix: Set correct permissions
sudo chown -R trong.doan:trong.doan /var/www/hmvc_and_rbs/
sudo chmod -R 755 /var/www/hmvc_and_rbs/
```

### **5. Memory Issues**
```bash
# Lỗi: Out of memory
# Fix: Restart services
sudo systemctl restart puma-hmvc-staging.service
sudo systemctl restart nginx
```

## 📋 **QUICK DEBUGGING SCRIPT**

```bash
#!/bin/bash
# Chạy script này để check tất cả logs một lần

echo "=== NGINX LOGS ==="
sudo tail -10 /var/log/nginx/error.log

echo "=== RAILS LOGS ==="
tail -20 /var/www/hmvc_and_rbs/current/log/staging.log

echo "=== PUMA LOGS ==="
sudo journalctl -u puma-hmvc-staging.service --since '10 minutes ago'

echo "=== DATABASE STATUS ==="
sudo systemctl status postgresql --no-pager

echo "=== PUMA STATUS ==="
sudo systemctl status puma-hmvc-staging.service --no-pager

echo "=== NGINX STATUS ==="
sudo systemctl status nginx --no-pager

echo "=== MEMORY USAGE ==="
free -h

echo "=== DISK SPACE ==="
df -h
```

## 🎯 **CÁCH SỬ DỤNG**

1. **Khi gặp lỗi 500**: Chạy script quick debugging ở trên
2. **Check logs theo thứ tự**: Nginx → Rails → Puma → Database
3. **Fix lỗi**: Dựa vào error message trong logs
4. **Restart services**: Sau khi fix xong
5. **Test lại**: Truy cập website để xem còn lỗi không

## 🚀 **CÁCH SỬ DỤNG NGAY**

```bash
# Chạy script quick debugging
bash STAGING_ERROR_DEBUGGING.md

# Hoặc chạy từng lệnh riêng lẻ
sudo tail -n 100 /var/log/nginx/error.log
tail -n 100 /var/www/hmvc_and_rbs/current/log/staging.log
sudo journalctl -u puma-hmvc-staging.service -n 100
```

## 📝 **LƯU Ý QUAN TRỌNG**

- **Rails staging config**: `config.log_level = "info"` (có thể đổi thành "debug" để xem chi tiết hơn)
- **Log rotation**: Logs có thể bị rotate, check cả file cũ
- **Time zone**: Server có thể khác timezone, check timestamp
- **Multiple workers**: Puma có thể có nhiều worker, check tất cả logs
