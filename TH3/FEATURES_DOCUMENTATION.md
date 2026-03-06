# Ứng Dụng Đặt Đồ Ăn Online - Hướng Dẫn Tính Năng

## 📋 TỔNG QUAN HỆ THỐNG

Ứng dụng Flutter hoàn chỉnh cho khách hàng (User) và Quản trị viên (Admin) với tích hợp Firebase Firestore và Firebase Authentication.

---

## 👤 CHỨC NĂNG CHO KHÁCH HÀNG (USER)

### 1.1 **Đăng ký / Đăng nhập**
- **Đăng ký tài khoản**: Nhập email, mật khẩu, và tên
- **Đăng nhập**: Xác thực bằng email/mật khẩu
- **Quên mật khẩu**: Gửi email đặt lại mật khẩu
- **Đăng xuất**: Truy cập từ menu Hồ sơ
- **Tự động định tuyến**: Hệ thống tự động đưa Admin vào AdminHomeScreen và User vào HomeScreen

### 1.2 **Xem danh sách món ăn**
- Hiển thị danh sách món ăn dạng lưới (Grid)
- **Phân loại món**: Click vào các thẻ danh mục ở đầu màn hình
- **Tìm kiếm món ăn**: Thanh tìm kiếm ở đầu màn hình
- **Lọc theo giá**: Click nút Lọc (🔧) để chọn khoảng giá
- Hiển thị tên, giá, và mức đánh giá (sao) cho mỗi món

### 1.3 **Xem chi tiết món ăn**
- Click vào bất kỳ thẻ món nào để xem:
  - Hình ảnh món ăn (lớn hơn)
  - Mô tả chi tiết
  - Giá tiền
  - Đánh giá sao
  - Nút "Thêm vào giỏ hàng"

### 1.4 **Giỏ hàng**
- **Thêm món vào giỏ**: Click nút (+) trên thẻ món
- **Tăng/giảm số lượng**: Trong màn hình giỏ hàng, dùng nút -/+
- **Xóa món khỏi giỏ**: Click nút xóa (🗑️) trên các mục
- **Xem tổng tiền**: Hiển thị ở cuối màn hình giỏ
- **Icon giỏ hàng**: Hiển thị số lượng mục trong AppBar

### 1.5 **Đặt hàng**
- Nhập thông tin:
  - Họ tên người nhận
  - Số điện thoại
  - Địa chỉ giao hàng
- **Chọn phương thức thanh toán**:
  - Thanh toán khi nhận hàng (COD)
  - Chuyển khoản ngân hàng
- **Xác nhận đặt hàng**: Ghi lại thông tin vào Firestore
- Giỏ tự động được xóa sau khi đặt hàng

### 1.6 **Quản lý đơn hàng**
- **Xem lịch sử đơn hàng**: Click icon Hóa đơn (🧾) trong AppBar
- **Xem trạng thái đơn hàng**:
  - 🟠 Chờ xác nhận (pending)
  - 🔵 Đã xác nhận (confirmed)
  - 🟣 Đang giao hàng (shipping)
  - 🟢 Đã giao (delivered)
  - 🔴 Đã hủy (cancelled)
- **Thông tin đơn hàng**: Mã đơn, danh sách món, tổng tiền, địa chỉ

### 1.7 **Hồ sơ cá nhân**
- **Xem thông tin**: Click icon Người dùng (👤) trong AppBar
  - Email (không thể thay đổi)
  - Họ tên
  - Số điện thoại
  - Địa chỉ
- **Cập nhật thông tin**: Click nút Sửa (✏️)
- **Thay đổi mật khẩu**: Nút "Thay đổi mật khẩu"
- **Đăng xuất**: Nút "Đăng xuất"

---

## 🔐 CHỨC NĂNG CHO ADMIN (QUẢN TRỊ VIÊN)

> Admin được định tuyến tự động vào AdminHomeScreen khi có thuộc tính `role: 'admin'` trong Firestore

### 2.1 **Quản lý Món ăn**
- **Thêm món ăn**: Màn hình admin_manage_foods_screen (đã tồn tại)
- **Sửa món ăn**: Edit trong danh sách
- **Xóa món ăn**: Delete từ menu
- **Cập nhật giá**: Trong màn hình sửa

### 2.2 **Quản lý Danh mục**
- **Thêm danh mục**: Click nút (+) - Dialog thêm tên + URL hình ảnh
- **Sửa danh mục**: Menu tùy chọn → Sửa
- **Xóa danh mục**: Menu tùy chọn → Xóa
- **Danh sách danh mục**: Hiển thị tên, hình ảnh, chức năng

### 2.3 **Quản lý Đơn hàng**
- **Xem danh sách đơn hàng**: Tất cả đơn từ mọi khách hàng
- **Xem chi tiết đơn**: Click "Chi tiết" để xem toàn bộ thông tin
- **Cập nhật trạng thái**: Các trạng thái theo quy trình
  - Chờ xác nhận → Đã xác nhận
  - Đã xác nhận → Đang giao hàng
  - Đang giao hàng → Đã giao
  - Hủy đơn hàng (bất kỳ lúc nào)
- **Làm mới danh sách**: Swipe down để refresh

### 2.4 **Quản lý Người dùng**
- **Xem danh sách người dùng**: Tất cả user trong hệ thống
- **Xem chi tiết người dùng**: Tên, email, SĐT, địa chỉ, vai trò
- **Khóa tài khoản**: Vô hiệu hóa tài khoản người dùng
- **Mở khóa tài khoản**: Kích hoạt lại tài khoản đã khóa
- **Trạng thái hiển thị**: Badge xanh (Hoạt động) / đỏ (Bị khóa)

### 2.5 **Thống kê**
- Có thể truy cập các hàm:
  - `getTotalOrders()`: Tổng số đơn hàng
  - `getTotalRevenue()`: Tổng doanh thu

---

## 🗄️ CẤU TRÚC DỮ LIỆU FIRESTORE

### Collections
```
users/
├── {uid}
│   ├── uid: string
│   ├── email: string
│   ├── name: string
│   ├── phone: string
│   ├── address: string
│   ├── role: "user" | "admin"
│   ├── isActive: boolean
│   └── createdAt: timestamp

foods/
├── {foodId}
│   ├── name: string
│   ├── description: string
│   ├── price: double
│   ├── imageUrl: string
│   ├── categoryId: string (FK)
│   ├── rating: double
│   └── createdAt: timestamp

categories/
├── {categoryId}
│   ├── name: string
│   ├── imageUrl: string
│   └── createdAt: timestamp

orders/
├── {orderId}
│   ├── userId: string (FK)
│   ├── items: [{
│   │   ├── foodId: string
│   │   ├── foodName: string
│   │   ├── quantity: int
│   │   ├── price: double
│   │   └── totalPrice: double
│   │ }]
│   ├── totalAmount: double
│   ├── deliveryAddress: string
│   ├── paymentMethod: "cash" | "bank"
│   ├── status: "pending" | "confirmed" | "shipping" | "delivered" | "cancelled"
│   ├── orderDate: timestamp
│   ├── deliveryDate: timestamp (null nếu chưa giao)
│   ├── userPhone: string
│   └── userName: string
```

---

## 📁 CẤU TRÚC FILE DỰ ÁN

```
lib/
├── main.dart                          # Entry point, routing logic
├── firebase_options.dart              # Firebase config
├── models/
│   ├── food_model.dart               # Food model
│   ├── category_model.dart           # Category model
│   ├── order_model.dart              # Order & OrderItem models
│   ├── user_model.dart               # User model
│   └── cart_model.dart               # Cart & CartItem models
├── services/
│   └── firebase_service.dart         # Tất cả Firebase operations
├── screens/
│   ├── login_screen.dart             # Đăng nhập/Đăng ký/Quên mật khẩu
│   ├── home_screen.dart              # Trang chủ - Danh sách món
│   ├── food_detail_screen.dart       # Chi tiết món ăn
│   ├── cart_screen.dart              # Giỏ hàng
│   ├── checkout_screen.dart          # Thanh toán/Đặt hàng
│   ├── order_tracking_screen.dart    # Lịch sử & trạng thái đơn
│   ├── profile_screen.dart           # Hồ sơ cá nhân
│   └── admin/
│       ├── admin_home_screen.dart        # Menu admin chính
│       ├── admin_manage_foods_screen.dart # Quản lý món ăn
│       ├── admin_categories_screen.dart   # Quản lý danh mục
│       ├── admin_orders_screen.dart       # Quản lý đơn hàng
│       └── admin_users_screen.dart        # Quản lý người dùng
```

---

## 🚀 CÁCH SỬ DỤNG

### Cho Khách Hàng
1. **Trang đầu tiên**: Đăng nhập hoặc Đăng ký tài khoản
2. **Trang chủ**: Duyệt danh sách món ăn
3. **Tìm kiếm & Lọc**: Dùng thanh tìm kiếm và nút lọc
4. **Thêm vào giỏ**: Click (+) trên thẻ món
5. **Xem giỏ hàng**: Click icon 🛒 trong AppBar
6. **Thanh toán**: Click "Tiến hành thanh toán"
7. **Xem đơn hàng**: Click icon 🧾 để theo dõi trạng thái

### Cho Admin
1. **Đăng nhập**: Dùng tài khoản admin
2. **Trang chính**: 4 thẻ menu: Món ăn, Danh mục, Đơn hàng, Khách hàng
3. **Quản lý**: Click vào mục để quản lý
4. **Cập nhật**: Dùng menu tùy chọn (•••) hoặc nút (+)

---

## 🔧 FIREBASE SETUP

Cần cấu hình Firebase với:
- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore Database
- ✅ Collections đã được định nghĩa ở trên

---

## ✨ TÍNH NĂNG NỖI BẬT

- 🔐 **Xác thực an toàn**: Firebase Auth
- 🎯 **Tìm kiếm & Lọc**: Theo tên, danh mục, giá
- 🛒 **Giỏ hàng**: Lưu trữ trong session (refresh sẽ mất)
- 📱 **Responsive**: Tối ưu cho mobile
- 🎨 **Giao diện đẹp**: Sử dụng Material 3
- 🔄 **Real-time**: Dữ liệu từ Firestore
- 👥 **Phân quyền**: Tách biệt User/Admin
- 📊 **Quản lý toàn diện**: Từ menu cho admin

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Session Cart**: Giỏ hàng chỉ lưu khi ứng dụng chạy, không persist vào database
2. **Admin Check**: Cần tạo user có `role: "admin"` trong Firestore
3. **Permissions**: Cần cấu hình Firestore Rules cho phù hợp
4. **Images**: Dùng URL từ internet, cần có quyền truy cập

---

## 📞 HỖ TRỢ

Nếu gặp lỗi:
- Kiểm tra Firebase configuration
- Đảm bảo internet connection
- Xem error logs trong console
- Kiểm tra Firestore Rules và data structure

---

**Ứng dụng hoàn toàn sẵn sàng sử dụng!** 🎉
