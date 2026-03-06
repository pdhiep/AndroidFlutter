# 🔧 DEBUG: ADMIN ROLE ISSUE

## Các lỗi đã sửa:

### ✅ 1. Lỗi `toDouble()` - Price field
**Vấn đề:** Price lưu là empty string `""` → gọi `.toDouble()` fail
```
NoSuchMethodError: 'toDouble' Dynamic call failed.
Tried to invoke 'null' like a method.
```

**Giải pháp:** Thêm try-catch an toàn trong `Food.fromFirestore()`:
```dart
double price = 0.0;
try {
  final priceData = data['price'];
  if (priceData == null || priceData == '') {
    price = 0.0;
  } else if (priceData is double) {
    price = priceData;
  } else if (priceData is int) {
    price = priceData.toDouble();
  } else if (priceData is String) {
    price = double.tryParse(priceData) ?? 0.0;
  }
} catch (e) {
  price = 0.0;
}
```
✅ **File sửa:** `lib/models/food_model.dart`

---

### ✅ 2. Lỗi `int` vs `String` - Phone field
**Vấn đề:** Phone lưu là `int` (339004121) nhưng code expect String
```
TypeError: type 'int' is not a subtype of type 'String'
```

**Giải pháp:** Convert int → String trong `UserModel.fromFirestore()`:
```dart
String phone = '';
final phoneData = data['phone'];
if (phoneData != null) {
  if (phoneData is String) {
    phone = phoneData;
  } else if (phoneData is int) {
    phone = phoneData.toString();  // ← Convert int to String
  }
}
```
✅ **File sửa:** `lib/models/user_model.dart`

---

### ✅ 3. Lỗi Firestore Index - Multiple `.where()` clauses
**Vấn đề:** Query có nhiều `.where()` clauses → Firestore yêu cầu composite index
```
Exception: Lỗi tại hộ sơ: [cloud_firestore/failed-precondition] 
The query requires an index. You can create it here: ...
```

**Giải pháp:** 
- Chỉ dùng 1 `.where()` trên Firestore (categoryId)
- Lọc price range + search **in-app** (client-side)

```dart
Query query = _firestore.collection('foods');

// Chỉ 1 where clause
if (categoryId.isNotEmpty) {
  query = query.where('categoryId', isEqualTo: categoryId);
}

// Lọc in-app (không cần index)
if (minPrice != null) {
  foods = foods.where((food) => food.price >= minPrice).toList();
}
if (maxPrice != null) {
  foods = foods.where((food) => food.price <= maxPrice).toList();
}
```
✅ **File sửa:** `lib/services/firebase_service.dart`

---

### ✅ 4. Admin Role Check - Cải thiện logic
**Vấn đề:** Admin đăng nhập nhưng vẫn vào HomeScreen (user screen)

**Nguyên nhân:**
- Tạo new `FirebaseService()` mỗi lần → có thể cache issue
- Role string có thể có whitespace (`' admin'`, `'admin '`)
- Error không được log → khó debug

**Giải pháp:**
```dart
class UserRoleChecker extends StatelessWidget {
  final User user;
  late final FirebaseService _firebaseService;  // ← Reuse instance

  UserRoleChecker({super.key, required this.user}) {
    _firebaseService = FirebaseService();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _firebaseService.getUserProfile(user.uid),
      builder: (context, snapshot) {
        // ... loading state

        if (snapshot.hasError) {  // ← Show error instead of default to HomeScreen
          return Scaffold(
            body: Center(child: Text('Lỗi: ${snapshot.error}')),
          );
        }

        if (snapshot.data == null) {
          return const HomeScreen();
        }

        final userProfile = snapshot.data!;
        final role = userProfile.role.toLowerCase().trim();  // ← Normalize role

        print('DEBUG: User role = "$role" (admin=${role == 'admin'})');  // ← Debug log

        if (role == 'admin') {
          return const AdminHomeScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
```
✅ **File sửa:** `lib/main.dart`

---

## 📋 KIỂM TRA FIRESTORE

Đảm bảo admin document có format đúng:

```json
// ✅ ĐÚNG
{
  "uid": "cXHsIXCZYNaWw5Ex...",
  "email": "admin@example.com",
  "name": "Administrator",
  "role": "admin",
  "phone": "",
  "address": "",
  "isActive": true,
  "createdAt": timestamp
}

// ❌ SAI (role bị lưu sai)
{
  "role": "Admin"  // ← Phải lowercase
  "role": " admin"  // ← Không được có space
  "role": null  // ← Phải có value
}
```

---

## 🧪 KIỂM TRA BƯỚC BƯỚC

1. **Reset app:** Xóa app trên điện thoại → Re-run
2. **Đăng nhập admin:**
   - Email: *admin@example.com*
   - Pass: *password123*
3. **Mở DevTools / Xem logs:**
   - Tìm dòng: `DEBUG: User role = "admin" (admin=true)`
   - **Nếu thấy `admin=true`** → Chuyển AdminHomeScreen ✅
   - **Nếu thấy `admin=false` hoặc `admin=user`** → Role bị sai trong Firestore

4. **Kiểm tra Firestore:**
   - Vào Collections → users → [admin document]
   - Xác nhận `role` field = `"admin"` (không phải `"Admin"` hay `"Admin "`)

---

## 🔍 Nếu vẫn lỗi

### Option 1: Reset hoàn toàn
```bash
# Xóa cache
flutter clean
flutter pub get

# Build lại
flutter run
```

### Option 2: Xóa admin user cũ + tạo lại
1. Vào Firebase Auth → Xóa admin user
2. Vào Firestore → Xóa admin document
3. Gọi hàm `createAdminAccount()` lại:
```dart
FirebaseService firebaseService = FirebaseService();
await firebaseService.createAdminAccount('admin@example.com', 'password123', 'Admin');
```

### Option 3: Tạo admin thủ công trên Firebase Console
1. Firebase Auth → Add user → admin@example.com / password123
2. Copy UID
3. Firestore → users → Add document → Document ID = UID
4. Thêm fields:
```json
{
  "uid": "[copied UID]",
  "email": "admin@example.com",
  "name": "Admin",
  "role": "admin",
  "phone": "",
  "address": "",
  "isActive": true,
  "createdAt": [timestamp]
}
```

---

## 📊 Ticket Tracking

| Lỗi | Nguyên nhân | Fix | File |
|-----|-----------|-----|------|
| toDouble() | Price = "" | Try-catch | food_model.dart |
| int vs String | Phone type | Convert | user_model.dart |
| Firestore Index | Many .where() | In-app filter | firebase_service.dart |
| Admin role | Role normalize | Lowercase + trim | main.dart |

✅ **Tất cả 4 lỗi đã được sửa!**
