# Turbo Knowledge Summary

## Table of Contents
- [Turbo Frame](#turbo-frame)
- [Turbo Stream](#turbo-stream) *(Coming Soon)*
- [Turbo Drive](#turbo-drive) *(Coming Soon)*
- [Turbo Native](#turbo-native) *(Coming Soon)*

---

## Turbo Frame

### Khái niệm
Turbo Frame cho phép cập nhật một phần của trang mà không cần reload toàn bộ trang.

### Cách hoạt động
1. **Frame Container**: Định nghĩa vùng cần cập nhật
2. **Frame Target**: Chỉ định frame nào sẽ được cập nhật
3. **Partial Response**: Server trả về HTML cho frame đó

### Cú pháp cơ bản

#### 1. Tạo Frame Container
```erb
<%= turbo_frame_tag "frame_name" do %>
  <!-- Nội dung ban đầu -->
<% end %>
```

#### 2. Link với Frame Target
```erb
<%= link_to "View Details", todo_path(todo), 
    data: { turbo_frame: "frame_name" } %>
```

#### 3. Response từ Server
```erb
<%= turbo_frame_tag "frame_name" do %>
  <!-- Nội dung mới -->
<% end %>
```

### Demo thực tế từ code hiện tại

#### File: `app/views/todos/index.html.erb`
```erb
<!-- Link xem chi tiết -->
<%= link_to todo_path(todo), 
    data: { turbo_frame: "todo_details_frame", turbo_action: "advance" } do %>
  <svg><!-- Eye icon --></svg>
<% end %>

<!-- Frame container ở cuối trang -->
<%= turbo_frame_tag "todo_details_frame" do %><% end %>
```

#### File: `app/views/todos/show.html.erb`
```erb
<%= turbo_frame_tag "todo_details_frame" do %>
  <div class="bg-white p-6 rounded-lg shadow">
    <h2><%= @todo.title %></h2>
    <p><%= @todo.description %></p>
    <!-- Chi tiết todo -->
  </div>
<% end %>
```

## 🎯 Turbo Actions - Tóm Tắt Ngắn Gọn

### 1. `turbo_action: "advance"`
```erb
data: { turbo_frame: "details", turbo_action: "advance" }
```
- ✅ Cập nhật frame
- ✅ Thay đổi URL
- ✅ Thêm vào browser history (có thể Back)

### 2. `turbo_action: "replace"`
```erb
data: { turbo_frame: "details", turbo_action: "replace" }
```
- ✅ Cập nhật frame
- ✅ Thay đổi URL
- ❌ Thay thế history (không thể Back)

### 3. `turbo_frame: "_top"`
```erb
data: { turbo_frame: "_top" }
```
- ✅ Tải lại toàn bộ trang
- ❌ Không dùng frame

### 4. `turbo_frame: "_self"`
```erb
data: { turbo_frame: "_self" }
```
- ✅ Cập nhật frame hiện tại
- ❌ Chỉ hoạt động khi link nằm trong frame

## 🧪 Test Nhanh

### Test `advance` vs `replace`:
1. Click todo 1 → Click todo 2
2. Nhấn nút **Back** của browser:
   - `advance`: Quay lại todo 1
   - `replace`: Quay thẳng về danh sách

## 💡 Khi Nào Dùng Gì?

| Action | Dùng Khi |
|--------|----------|
| `advance` | Xem chi tiết, navigation bình thường |
| `replace` | Form submit, không muốn user quay lại |
| `_top` | Thoát khỏi frame, tải lại trang |
| `_self` | Cập nhật frame chứa link |

## ⚠️ Lưu Ý Quan Trọng

### Cú pháp đúng:
```erb
<!-- ✅ ĐÚNG -->
data: { 
  turbo_frame: "details", 
  turbo_action: "advance" 
}

<!-- ❌ SAI -->
data: { turbo_frame: "details" },
turbo_action: "advance"
```

### Frame name phải khớp:
```erb
<!-- Link -->
data: { turbo_frame: "todo_details_frame" }

<!-- Response -->
<%= turbo_frame_tag "todo_details_frame" do %>
  <!-- content -->
<% end %>
```

## 🎯 Kết Luận

- **`advance`**: Dùng nhiều nhất, navigation bình thường
- **`replace`**: Dùng khi không muốn user quay lại
- **`_top`**: Dùng khi muốn thoát khỏi frame
- **`_self`**: Dùng khi muốn cập nhật frame hiện tại

### Use Cases phù hợp
- Xem chi tiết item trong danh sách
- Cập nhật sidebar
- Modal content
- Tab switching
- Search results

---

## Turbo Stream *(Coming Soon)*
*Sẽ cập nhật khi cần thiết*

## Turbo Drive *(Coming Soon)*
*Sẽ cập nhật khi cần thiết*

## Turbo Native *(Coming Soon)*
*Sẽ cập nhật khi cần thiết*

---

## Quick Reference

### Turbo Frame Checklist
- [ ] Định nghĩa frame container với `turbo_frame_tag`
- [ ] Thêm `data: { turbo_frame: "name" }` vào link
- [ ] Response trả về cùng frame name
- [ ] Test navigation và URL update
- [ ] Kiểm tra không có lỗi console

### Common Patterns
```erb
<!-- Pattern 1: Details View -->
<%= link_to "View", item_path(item), data: { turbo_frame: "details" } %>
<%= turbo_frame_tag "details" do %><% end %>

<!-- Pattern 2: Form in Modal -->
<%= link_to "Edit", edit_item_path(item), data: { turbo_frame: "modal" } %>
<%= turbo_frame_tag "modal" do %><% end %>

<!-- Pattern 3: Search Results -->
<%= form_with url: search_path, data: { turbo_frame: "results" } do |f| %>
  <%= f.text_field :query %>
  <%= f.submit "Search" %>
<% end %>
<%= turbo_frame_tag "results" do %><% end %>
```

### Debug Tips
1. **Kiểm tra Console**: Mở DevTools xem có lỗi gì không
2. **Kiểm tra Network**: Xem request có được gửi không
3. **Kiểm tra Response**: Response có đúng format không
4. **Kiểm tra Frame Name**: Frame name có khớp không
5. **Kiểm tra Cú pháp**: Tất cả attributes có nằm trong `data: {}` không
