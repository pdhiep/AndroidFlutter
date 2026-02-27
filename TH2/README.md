# Smart Note

Ứng dụng Smart Note — bài thực hành môn Lập trình Mobile (Flutter).

Mục tiêu: CRUD ghi chú + lưu trữ cục bộ (SharedPreferences), JSON serialization,
quản lý navigation và cập nhật state bất đồng bộ.

## Tính năng chính

- Tạo, đọc, sửa, xóa ghi chú (CRUD).
- Lưu toàn bộ danh sách ghi chú vào `SharedPreferences` dưới dạng JSON.
- Giao diện chính hiển thị danh sách ghi chú theo lưới 2 cột (Masonry/Staggered).
- Thanh tìm kiếm lọc kết quả real-time theo **Tiêu đề**.
- Màn hình soạn thảo tự động lưu khi người dùng thoát (Auto-save) — không có nút "Lưu".
- Vuốt để xóa (Swipe to delete) kèm hộp thoại xác nhận và chức năng "Hoàn tác" (Undo).
- Empty state: hiển thị ảnh minh họa mờ và thông báo khi chưa có ghi chú.
- Giao diện sử dụng Material Design 3 (đã bật `useMaterial3`).

## Chi tiết kỹ thuật

- Model: `Note` (`lib/models/note.dart`) chứa `id`, `title`, `content`, `dateTime`.
	- Có `toMap()` / `fromMap()` và 2 phương thức `encode(List<Note>)` / `decode(String)` dùng
		`json.encode` / `json.decode`.
- Lưu/đọc: `SharedPreferences` key: `notes_data`.
- Màn hình chính: `lib/screens/home_screen.dart`
	- AppBar hiển thị: `Smart Note - [Phạm Đức Hiệp] - [2251161997]`.
	- Thanh tìm kiếm bo góc, icon kính lúp, lọc real-time theo tiêu đề.
	- Dùng `MasonryGridView` từ `flutter_staggered_grid_view` để hiển thị thẻ.
	- Thẻ (Card): bo góc, đổ bóng nhẹ, Title in đậm 1 dòng (ellipsis), nội dung tối đa 3 dòng,
		thời gian hiển thị `dd/MM/yyyy HH:mm` (package `intl`).
	- Empty state dùng `assets/empty.svg` (hiện đã thêm) qua `flutter_svg`.
	- Vuốt trái để xóa (`Dismissible`) với nền đỏ và icon thùng rác, kèm dialog xác nhận.
	- Sau khi xóa thành công sẽ hiện `SnackBar` có nút `Hoàn tác` để phục hồi ghi chú.
- Màn hình soạn thảo: `lib/screens/edit_screen.dart`
	- TextField cho `title` và `content` (multiline, tự co giãn chiều cao), không có viền.
	- Khi người dùng thoát màn hình (Back button / gesture), `WillPopScope` gọi hàm
		tự tạo hoặc cập nhật `Note` và `Navigator.pop(context, savedNote)` để trả về cho Home.
	- `Home` nhận `Note` trả về, cập nhật danh sách và lưu lại `SharedPreferences`.

## Dependencies (đã khai báo trong `pubspec.yaml`)

- `shared_preferences`
- `flutter_staggered_grid_view`
- `flutter_svg` (hiển thị ảnh SVG cho empty state)
- `intl` (định dạng thời gian)

## Hướng dẫn chạy

1. Cài Flutter theo hướng dẫn chính thức: https://flutter.dev
2. Ở thư mục dự án chạy:

```bash
flutter pub get
flutter run
```

3. Test các thao tác bắt buộc:
	- Tạo ghi chú mới, thoát bằng nút Back — ghi chú tự lưu.
	- Sửa ghi chú: vào ghi chú cũ, sửa, Back — ghi chú cập nhật thời gian.
	- Vuốt để xóa: xác nhận dialog => thấy SnackBar cho phép Hoàn tác.
	- Kill app (đóng hoàn toàn) hoặc restart emulator — mở lại app vẫn thấy dữ liệu.

## YÊU CẦU KỸ THUẬT & KIỂM THỬ (OFFLINE, PERSISTENCE)

- Ứng dụng hoạt động hoàn toàn offline: mọi tính năng CRUD và lưu/đọc ghi chú không phụ thuộc mạng.
- Mọi dữ liệu (Tiêu đề, Nội dung, Thời gian) được đóng gói vào `Note` model và chuyển
	đổi sang chuỗi JSON bằng `Note.encode()` / `Note.decode()` (dựa trên `json.encode`/`json.decode`) trước
	khi ghi/đọc với `SharedPreferences`.
- Key lưu trên `SharedPreferences`: `notes_data` (chuỗi JSON của List<Note>).

### Bài test bắt buộc (Kiểm tra persistence sau khi kill app)

1. Mở ứng dụng, tạo vài ghi chú (ít nhất 2-3), đảm bảo mỗi ghi chú có tiêu đề và nội dung.
2. Đóng ứng dụng hoàn toàn (Kill app) thông qua đa nhiệm hoặc tắt tiến trình trên emulator/device.
3. (Tùy chọn) Hoặc khởi động lại emulator/virtual device.
4. Mở lại ứng dụng — danh sách ghi chú phải giữ nguyên và hiển thị đúng tiêu đề, nội dung và thời gian.

Nếu dữ liệu mất, kiểm tra lại xem `SharedPreferences` đã được ghi thành công khi thoát `EditScreen` hoặc
khi thao tác xóa/thêm ghi chú. Mã của dự án đã đảm bảo lưu trực tiếp trong `EditScreen` khi người dùng Back,
và `HomeScreen` cũng ghi lại danh sách khi nhận dữ liệu trả về.

## Kiểm điểm & Ghi chú

- ID ghi chú hiện tạo bằng `DateTime.now().toString()` — đủ dùng cho bài tập; nếu cần
	có thể đổi sang UUID.
- Nếu muốn ảnh minh họa khác, đặt file vào `assets/` và đăng ký trong `pubspec.yaml`.
- Có thể mở rộng: thêm tag, màu nền thẻ theo tag, export/import JSON, backup.

## Các file quan trọng

- `lib/models/note.dart` — Model + encode/decode JSON
- `lib/screens/home_screen.dart` — Home, tìm kiếm, danh sách, xóa, undo
- `lib/screens/edit_screen.dart` — Soạn thảo, auto-save khi Back
- `lib/main.dart` — Bật Material 3, khởi tạo app
- `pubspec.yaml` — dependencies và assets (`assets/empty.svg`)

---

Nếu bạn muốn, tôi có thể:
- Thêm hướng dẫn chi tiết để build APK/IPA.
- Thay `DateTime` id bằng UUID.
- Cải thiện style thẻ để phù hợp Material 3 hơn.

Cho tôi biết bạn muốn thêm gì nữa.

