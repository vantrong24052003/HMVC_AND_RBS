# Turbo Knowledge Summary

## Table of Contents
- [Turbo Frame](#turbo-frame)
- [Turbo Stream](#turbo-stream)
- [Turbo Drive](#turbo-drive)
- [Turbo Native](#turbo-native)

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

## Turbo Drive

### Khái niệm
Turbo Drive tự động chặn (intercept) các navigation (click link) và form submissions để tải trang kế tiếp qua XHR, thay vì full reload. Nó giữ lại layout, chỉ thay đổi `<body>` và cập nhật lịch sử trình duyệt mượt mà.

### Hành vi mặc định
- Link `<a>` và form `<form>` sẽ được Turbo xử lý nếu không tắt.
- Navigation sẽ:
  - Tải HTML trang đích qua XHR
  - Thay thế `<body>` và cập nhật `document.title`
  - Đẩy entry vào browser history (có thể Back/Forward)
- Form submit có thể là GET/POST/PUT/PATCH/DELETE (theo Rails UJS)

### Cấu hình nhanh
- Tắt Turbo Drive cho một phần tử hoặc cây DOM:
```erb
<!-- Tắt cho một link -->
<%= link_to "Go", some_path, data: { turbo: false } %>

<!-- Tắt cho một form -->
<%= form_with ..., data: { turbo: false } do |f| %>
  ...
<% end %>

<!-- Tắt toàn cục (không khuyến nghị) -->
<meta name="turbo-visit-control" content="reload">
```
- Buộc reload toàn trang khi click link:
```erb
<%= link_to "Hard reload", path, data: { turbo: "false" } %>
```
- Chuyển hướng ra khỏi frame (trong Turbo Frame):
```erb
<%= link_to "Open full", path, data: { turbo_frame: "_top" } %>
```

### Sự kiện (events) hữu ích
Bạn có thể lắng nghe các sự kiện để hook logic UI:
```javascript
document.addEventListener("turbo:load", () => {
  // Trang mới đã sẵn sàng sau một visit
});

document.addEventListener("turbo:before-visit", (e) => {
  // Trước khi điều hướng (có thể hủy bằng e.preventDefault())
});

document.addEventListener("turbo:before-cache", () => {
  // Trước khi trang hiện tại vào cache → dọn dẹp state UI (ẩn modal, reset video...)
});
```

### Cache & Restoration Visit
- Turbo Drive cache DOM của trang khi rời đi, để quay lại nhanh (Back/Forward)
- `turbo:before-cache` là thời điểm dọn dẹp DOM vì trạng thái UI sẽ được lưu trong cache
- Nếu muốn luôn reload dữ liệu khi quay lại, cân nhắc vô hiệu cache cho một số thành phần hoặc lắng nghe `turbo:load` để re-fetch

### Redirect & Status Codes
- 3xx redirect hoạt động bình thường với Turbo Drive
- Với form errors (422 Unprocessable Entity), server có thể render lại template hiện tại; Turbo sẽ thay thế body theo response
- Với Turbo Stream (mimetype `text/vnd.turbo-stream.html`), Turbo sẽ thực thi stream actions thay vì thay body

### Tương tác với Turbo Frame & Turbo Stream
- Turbo Drive lo phần navigation cấp trang (visit)
- Turbo Frame cập nhật từng vùng DOM
- Turbo Stream thực thi các hành động DOM (append/replace/remove...)
- Khi ở trong Frame muốn “thoát” ra navigation cấp trang: dùng `data: { turbo_frame: "_top" }`

### Mẫu dùng thực tế
- Link chuyển trang bình thường (Turbo Drive xử lý):
```erb
<%= link_to "Danh sách Todos", todos_path %>
```
- Form submit và giữ lại trên cùng một trang khi lỗi (422):
```ruby
# controller
if @form.errors.present?
  render :edit, status: :unprocessable_entity
else
  redirect_to todos_path, notice: "Todo updated successfully"
end
```
- Buộc reload toàn trang khi có asset/state phụ thuộc không tương thích với cache:
```erb
<meta name="turbo-visit-control" content="reload">
```

### Khi nào NÊN/NÊN KHÔNG dùng Turbo Drive
- Nên: hầu hết navigation và form tiêu chuẩn để có UX mượt, nhanh
- Không nên: trang phụ thuộc nặng vào JS khởi tạo lại toàn cục mà chưa tương thích với cache (khi đó tắt theo phần tử hoặc dùng `turbo:before-cache` để dọn dẹp)

---

## Turbo Native

### Khái niệm
Turbo Native giúp dựng app iOS/Android sử dụng WebView + Turbo để tái dụng tối đa web UI, nhưng vẫn có cảm giác native (navigation bar, tab bar, push/present). App native điều khiển điều hướng; phần nội dung là trang web của bạn.

### Kiến trúc tổng quát
- App Native (iOS/Android) = Shell điều hướng + WebView
- Turbo (Client) trong WebView vẫn hoạt động (Drive/Frame/Stream)
- Turbo Native Bridge (iOS `turbo-ios`, Android `turbo-android`) kết nối điều hướng native với URL của web app

### Thiết lập nhanh
- iOS (Swift):
  - Thêm dependency `Turbo` (CocoaPods/SPM)
  - Tạo `Session` + `VisitableViewController`
  - Định nghĩa `Navigator` để map URL → màn hình native hay web
- Android (Kotlin):
  - Thêm dependency `dev.hotwire:turbo-android`
  - Tạo `TurboSession` + `TurboActivity`/`TurboFragment`
  - Định nghĩa `Navigator` tương tự

Pseudo iOS (rút gọn):
```swift
let session = Session(webView: WKWebView())
session.delegate = self
navigator.route(URL(string: "https://your.app")!)
```

Pseudo Android (rút gọn):
```kotlin
val session = TurboSession(this)
session.navigator = AppNavigator(this)
session.visit("https://your.app")
```

### Chiến lược điều hướng
- Push (stack) vs Present (modal) do app native quyết định dựa trên URL
- Quy ước URL để phân biệt:
  - Web screens: `https://your.app/...`
  - Native screens: custom scheme, ví dụ `yourapp://settings`
- Có thể dùng `data-turbo-action="advance|replace"` trong web để gợi ý, nhưng app native luôn là nơi quyết định cuối cùng

### Tương tác đặc biệt
- Deep links: App nhận `yourapp://...` hoặc `https://your.app/...` → Navigator mở đúng màn hình
- Auth session/cookies: Chia sẻ cookie giữa Safari/WebView (iOS cần cấu hình `WKWebsiteDataStore`); đảm bảo login web áp dụng trong WebView
- File upload/camera: Bật quyền và bridge để WebView mở picker/camera; Android cần `WebChromeClient` phù hợp
- Pull-to-refresh: Do app native cung cấp; WebView reload URL hiện tại
- Offline/Errors: Intercept lỗi mạng → hiển thị native error screen, cho phép retry

### Form & Redirect
- Form trên web hoạt động bình thường với Turbo Drive
- 422 (validation error): WebView nhận HTML và cập nhật phần body (giống web)
- 3xx redirect: Giữ lịch sử điều hướng trong native stack

### An toàn & Hiệu năng
- Giới hạn origin được phép (App side) để tránh mở trang ngoài ý muốn
- Bật cache của WebView hợp lý; cân nhắc Clear khi logout
- Dùng `broadcast_*` (Turbo Stream) để realtime trong WebView như trên web

### Debug & Logging
- iOS: bật Web Inspector (Safari → Develop) để inspect WebView
- Android: `setWebContentsDebuggingEnabled(true)` để dùng Chrome DevTools
- Log lifecycle: visit started/completed, errors, redirects; đồng bộ với logs server

### Khi nào nên dùng Turbo Native
- Muốn xuất bản nhanh iOS/Android dựa trên web hiện có
- UI web chiếm đa số, nhưng cần shell/native navigation, deep links, push notifications
- Cần chia sẻ logic giao diện, realtime, forms giữa web và app

### Lưu ý tích hợp với dự án hiện tại
- Web đã dùng Turbo Drive/Frame/Stream → giữ nguyên
- Thêm quy ước URL rõ ràng để App Navigator định tuyến (ví dụ tiền tố `/native/` hay scheme riêng)
- Test: navigation stack, back/forward, modals, auth, upload, deep links, offline

---
