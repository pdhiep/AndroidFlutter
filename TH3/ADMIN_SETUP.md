# 🔧 HƯỚNG DẪN TẠO TÀI KHOẢN ADMIN

## ❌ Vấn đề

Khi đăng ký tài khoản trên ứng dụng, **mặc định role được gán là `'user'`**. Không có cách để tạo admin qua giao diện đăng ký.

---

## ✅ Giải pháp

### **Cách 1: Tạo Admin Thủ Công (Firebase Console)** 
*Dành cho development/testing*

#### Bước 1: Tạo Authentication User
1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project → **Authentication → Users**
3. Click **"Add user"** → Nhập email & password
4. **Copy UID** của user vừa tạo

#### Bước 2: Tạo Document Firestore
1. Vào **Firestore Database → Collections → "users"**
2. Click **"Add document"** → Dán UID làm document ID
3. Thêm các field:
```json
{
  "uid": "[UID từ Auth]",
  "email": "admin@example.com",
  "name": "Admin",
  "role": "admin",
  "phone": "",
  "address": "",
  "isActive": true,
  "createdAt": "[server timestamp]"
}
```
4. **Lưu** → Đăng nhập bằng email/password admin

---

### **Cách 2: Gọi Hàm `createAdminAccount()` từ Code**
*Tự động + An toàn hơn*

#### Trong main.dart hoặc một admin setup screen:
```dart
import 'services/firebase_service.dart';

final firebaseService = FirebaseService();

try {
  await firebaseService.createAdminAccount(
    'admin@example.com',
    'password123',
    'Administrator',
  );
  print('Admin account created successfully!');
} catch (e) {
  print('Error: $e');
}
```

**Tính năng:**
- ✅ Tạo Firebase Auth user
- ✅ Tạo Firestore document với role = 'admin'
- ✅ Try-catch error handling

---

### **Cách 3: Thêm Nút Setup Admin (Nếu chưa có user)**

Chỉnh sửa `login_screen.dart`:

```dart
// Thêm nút tạo admin dev
Padding(
  padding: const EdgeInsets.only(top: 12),
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    onPressed: () => _createDevAdmin(),
    child: const Text('Tạo Admin (Chỉ Dev)'),
  ),
)
```

Hàm tạo:
```dart
Future<void> _createDevAdmin() async {
  try {
    final firebaseService = FirebaseService();
    await firebaseService.createAdminAccount(
      'admin@example.com',
      'admin123456',
      'Administrator',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Admin account created! Email: admin@example.com'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}
```

---

## 📝 Kiểm Tra

Sau khi tạo admin:

1. **Đăng nhập** bằng email admin
2. **Kiểm tra Firestore**: Xem role = 'admin'
3. **Giao diện**: Nếu đúng → chuyển sang **AdminHomeScreen** ✓

---

## 🔑 Firestore Collections Structure

```
✅ users/
   ├── [uid1]
   │   ├── uid: "fI2kNxZ..."
   │   ├── email: "user@example.com"
   │   ├── name: "Nguyễn Văn A"
   │   ├── role: "user"          ← Regular user
   │   ├── phone: "0888......"
   │   ├── address: "123 Nguyen Hue"
   │   ├── isActive: true
   │   └── createdAt: timestamp
   │
   └── [uid2]
       ├── uid: "pJ5mOyA..."
       ├── email: "admin@example.com"
       ├── name: "Administrator"
       ├── role: "admin"         ← ADMIN!
       ├── phone: ""
       ├── address: ""
       ├── isActive: true
       └── createdAt: timestamp
```

---

## 🎯 Test Logic

**Role Check** (main.dart):
```dart
final userProfile = snapshot.data!;

if (userProfile.role == 'admin') {
  return AdminHomeScreen();  // ← Admin screens
} else {
  return HomeScreen();        // ← User screens
}
```

✅ Nếu `role == 'admin'` → Chuyển đến AdminHomeScreen
✅ Nếu `role == 'user'` → Chuyển đến HomeScreen

---

## ⚡ Quick Start

**Chọn 1 trong 2 cách:**

| Cách | Bước | Dễ | Speed |
|-----|------|-------|-------|
| **Firebase Console** | 2-3 click | ✅ | Nhanh |
| **`createAdminAccount()`** | 1 function call | ⭐ | Tự động |

**Khuyến nghị:** Dùng Cách 2 (`createAdminAccount()`) - an toàn hơn! 🚀
