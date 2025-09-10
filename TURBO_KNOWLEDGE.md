# Turbo Knowledge Summary

## Table of Contents
- [Turbo Frame](#turbo-frame)
- [Turbo Stream](#turbo-stream)
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

---

## Turbo Stream

### Khái niệm
Turbo Stream cho phép server gửi các "hành động DOM" (append, prepend, replace, remove, update) đến client qua HTTP response hoặc WebSocket (Turbo Socket). Client sẽ áp dụng thay đổi trực tiếp lên DOM.

### Cấu phần quan trọng
- **Channel (stream name)**: Tên kênh subscribe trên client và publish trên server. Ví dụ: `:todos`.
- **Target**: id của DOM element sẽ bị tác động. Ví dụ: `"todos"` cho `<tbody id="todos">`.
- **Partial**: Template để render HTML khi cần chèn/thay thế.
- **DOM id của record**: Mặc định theo `dom_id(record)` (vd: `todo_123`) và phải khớp `id` của phần tử trong HTML.

### View prerequisites (áp dụng CHUNG cho create/update/destroy)
- Trang nào muốn nhận realtime phải có:
```erb
<%= turbo_stream_from :todos %>
```
- Danh sách cần có target cố định:
```erb
<tbody id="todos">
  <% @form.each do |todo| %>
    <tr id="<%= dom_id(todo) %>"> ... </tr>
  <% end %>
</tbody>
```
- Partial hàng:
```erb
<!-- app/views/todos/_todo.html.erb -->
<tr id="<%= dom_id(todo) %>"> ... </tr>
```

---

## Todos — Config chuẩn cho 3 methods

### 1) Create
- Model `app/models/todo.rb`:
```ruby
after_create_commit -> { broadcast_append_to :todos, target: "todos" }
```
- Controller `app/controllers/todos_controller.rb`:
```ruby
def create
  operator = Todos::CreateOperation.new(params)
  operator.call
  @form = operator.form
  return render :new, status: :unprocessable_entity if @form.errors.present?

  redirect_to todos_path, notice: "Todo created successfully"
end
```
- View `index` đã có `turbo_stream_from :todos` và `tbody#todos`.

### 2) Update
- Model `app/models/todo.rb`:
```ruby
after_update_commit -> { broadcast_replace_to :todos }
```
- Controller `app/controllers/todos_controller.rb`:
```ruby
def update
  operator = Todos::UpdateOperation.new(params)
  operator.call
  @form = operator.form
  return render :new, status: :unprocessable_entity if @form.errors.present?

  redirect_to todos_path, notice: "Todo updated successfully"
end
```
- Yêu cầu DOM/Partial: `tr#<%= dom_id(todo) %>` và `_todo.html.erb` khớp markup.

### 3) Destroy
- Model `app/models/todo.rb`:
```ruby
after_destroy_commit -> { broadcast_remove_to :todos }
```
- Controller `app/controllers/todos_controller.rb` (fallback + flash khi Turbo):
```ruby
def destroy
  operator = Todos::DestroyOperation.new(params)
  operator.call
  @todo = operator.todo

  respond_to do |format|
    format.html { redirect_to todos_path, notice: "Todo deleted successfully" }
    format.turbo_stream do
      flash.now[:notice] = "Todo deleted successfully"
      render turbo_stream: [
        turbo_stream.remove(@todo),
        turbo_stream.update("flash", partial: "shared/flash", locals: { errors: [] })
      ]
    end
  end
end
```

### Lưu ý quan trọng
- `turbo_stream_from :todos` là subscription CHUNG, dùng cho cả 3 methods; chỉ cần đặt một lần trên trang cần realtime (ví dụ index).
- Target `"todos"` phải khớp `id` vùng danh sách; dom_id hàng phải khớp với partial.
- Controller chỉ cần redirect + flash. Realtime đã được model broadcast xử lý.
- Nên cố định sort ở index (vd: `Todo.order(created_at: :asc)`) để đa tab hiển thị đồng nhất khi replace.

---

## Turbo Drive *(Coming Soon)*
*Coming Soon*

## Turbo Native *(Coming Soon)*
*Coming Soon*
