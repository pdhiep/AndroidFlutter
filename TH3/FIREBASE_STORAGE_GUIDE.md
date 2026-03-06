# 🖼️ HƯỚNG DẪN THÊM FIREBASE STORAGE - UPLOAD HÌNH ẢNH

## 📋 TỔNG QUAN

Hiện tại app dùng imageUrl string (nhập thủ công). Cần thêm Firebase Storage để:
- ✅ Chọn ảnh từ thiết bị
- ✅ Upload lên Firebase Storage
- ✅ Lấy download URL
- ✅ Lưu URL vào Firestore

---

## 🚀 BƯỚC 1: Thêm Dependencies

Mở `pubspec.yaml` và thêm:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.20.0
  cloud_firestore: ^4.13.0
  firebase_auth: ^4.10.0
  firebase_storage: ^11.0.0      # ← THÊM CÁI NÀY
  image_picker: ^1.0.0            # ← THÊM CÁI NÀY
  
dev_dependencies:
  flutter_test:
    sdk: flutter
```

Chạy:
```bash
flutter pub get
```

---

## 🛠️ BƯỚC 2: Cấu Hình Firebase Storage

### 2.1 Trên Firebase Console

1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project **app_dat_do_an**
3. Vào **Storage** → **Get Started**
4. Chọn location (VD: asia-southeast1)
5. **Firestore Rules:**

```
rules_version = '2';
service firebase.googleapis.com {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      // Admin có thể upload/delete
      allow create, update, delete: if request.auth.token.role == 'admin';
      // Tất cả có thể đọc
      allow read: if true;
    }
  }
}
```

6. Click **Publish**

---

## 📝 BƯỚC 3: Tạo Hàm Upload trong Service

Sửa `lib/services/firebase_service.dart` - thêm hàm upload:

```dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;  // ← THÊM

  // ==================== IMAGE UPLOAD ====================
  
  /// Upload ảnh từ File và trả về download URL
  Future<String> uploadImage({
    required File imageFile,
    required String folderName,  // VD: 'foods', 'categories'
    String? fileName,
  }) async {
    try {
      // Nếu không có tên file, dùng timestamp
      fileName ??= 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Tham chiếu đến Firebase Storage
      Reference ref = _storage.ref().child('$folderName/$fileName');
      
      // Upload file
      UploadTask uploadTask = ref.putFile(imageFile);
      
      // Chờ upload hoàn tất
      TaskSnapshot snapshot = await uploadTask;
      
      // Lấy download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception("Lỗi upload ảnh: $e");
    }
  }

  /// Xóa ảnh từ Firebase Storage
  Future<void> deleteImage(String imagePath) async {
    try {
      await _storage.ref(imagePath).delete();
    } catch (e) {
      throw Exception("Lỗi xóa ảnh: $e");
    }
  }
}
```

---

## 🎨 BƯỚC 4: Sửa Admin Food Form Screen

Sửa `lib/screens/admin/admin_food_form_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  // ← THÊM
import 'dart:io';  // ← THÊM
import '../../models/food_model.dart';
import '../../models/category_model.dart';
import '../../services/firebase_service.dart';

class AdminFoodFormScreen extends StatefulWidget {
  final Food? existingFood;
  const AdminFoodFormScreen({super.key, this.existingFood});

  @override
  State<AdminFoodFormScreen> createState() => _AdminFoodFormScreenState();
}

class _AdminFoodFormScreenState extends State<AdminFoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = FirebaseService();

  late TextEditingController _nameCtrl, _descCtrl, _priceCtrl, _ratingCtrl;
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  
  File? _selectedImage;  // ← THÊM: Lưu file ảnh được chọn
  String? _imageUrl;     // ← THÊM: Lưu URL ảnh hiện tại

  @override
  void initState() {
    super.initState();
    final f = widget.existingFood;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _descCtrl = TextEditingController(text: f?.description ?? '');
    _priceCtrl = TextEditingController(text: f?.price.toStringAsFixed(0) ?? '');
    _ratingCtrl = TextEditingController(text: f?.rating.toString() ?? '5.0');
    _selectedCategoryId = f?.categoryId;
    _imageUrl = f?.imageUrl;  // ← THÊM

    _loadCategories();
  }

  // ← THÊM: Hàm chọn ảnh
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,  // Nén ảnh để giảm kích thước
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _apiService.fetchCategories();
      setState(() => _categories = cats);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ← SỬA: Hàm save món ăn (thêm upload ảnh)
  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đủ thông tin và chọn danh mục'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String imageUrl = _imageUrl ?? '';  // Dùng URL cũ nếu không chọn ảnh mới

      // Nếu có ảnh mới, upload lên Firebase Storage
      if (_selectedImage != null) {
        imageUrl = await _apiService.uploadImage(
          imageFile: _selectedImage!,
          folderName: 'foods',  // Folder trong Firebase Storage
          fileName: 'food_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // Nếu imageUrl vẫn trống, báo lỗi
      if (imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ảnh cho món ăn'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final newFood = Food(
        id: widget.existingFood?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        imageUrl: imageUrl,  // ← Dùng URL từ Firebase Storage
        categoryId: _selectedCategoryId!,
        rating: double.parse(_ratingCtrl.text.trim()),
      );

      if (widget.existingFood == null) {
        await _apiService.addFood(newFood);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm món thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _apiService.updateFood(newFood);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _ratingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingFood == null ? 'Thêm món ăn' : 'Sửa món ăn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ← THÊM: Preview ảnh
              if (_selectedImage != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_imageUrl != null && _imageUrl!.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Chưa chọn ảnh'),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // ← THÊM: Button chọn ảnh
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Chọn ảnh từ thư viện'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),

              // ← TỒN TẠI: Form fields
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên món ăn'),
                validator: (v) => v?.isEmpty ?? true ? 'Nhập tên' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Nhập mô tả' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Nhập giá' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ratingCtrl,
                decoration: const InputDecoration(labelText: 'Đánh giá (0-5)'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Nhập đánh giá' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                decoration: const InputDecoration(labelText: 'Danh mục'),
                validator: (v) => v == null ? 'Chọn danh mục' : null,
              ),
              const SizedBox(height: 24),

              // ← TỒN TẠI: Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.existingFood == null ? 'Thêm' : 'Cập nhật'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🎨 BƯỚC 5: Tương Tự Cho Categories

Sửa `lib/screens/admin/admin_categories_screen.dart`:

```dart
// Thêm import
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Trong dialog thêm/sửa category:
File? selectedImage;
String currentImageUrl = category?.imageUrl ?? '';

// Preview ảnh
if (selectedImage != null)
  Image.file(selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)
else if (currentImageUrl.isNotEmpty)
  Image.network(currentImageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),

// Button chọn ảnh
ElevatedButton.icon(
  onPressed: () async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  },
  icon: const Icon(Icons.image),
  label: const Text('Chọn ảnh'),
),

// Khi save
if (selectedImage != null) {
  currentImageUrl = await _firebaseService.uploadImage(
    imageFile: selectedImage!,
    folderName: 'categories',
  );
}

final cat = CategoryModel(
  id: category?.id ?? '',
  name: nameController.text,
  imageUrl: currentImageUrl,
);
```

---

## 🧪 BƯỚC 6: Test

1. **Rebuild app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Admin Add Food:**
   - Vào Admin → Quản lý Món Ăn
   - Click "Thêm Món"
   - Click "Chọn ảnh từ thư viện"
   - Chọn ảnh từ thiết bị
   - Điền thông tin khác
   - Click "Thêm"
   - ✅ Ảnh được upload + URL lưu vào Firestore

3. **Kiểm tra Firestore:**
   - Collections → foods
   - Xem imageUrl = URL từ Firebase Storage

4. **Kiểm tra Firebase Storage:**
   - Storage → foods/
   - Thấy các file ảnh upload

---

## 🚨 TROUBLESHOOT

### Lỗi: "The request.auth is null"
**Giải pháp:** Cập nhật Firestore Storage Rules:
```
allow create, update, delete: if request.auth != null && request.auth.token.role == 'admin';
allow read: if true;
```

### Lỗi: "Platform exception: Permission denied"
**Giải pháp:** 
- Kiểm tra permission trong `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Ảnh không hiển thị
**Giải pháp:**
- Kiểm tra imageUrl không null
- Thêm errorBuilder:
```dart
Image.network(
  imageUrl,
  errorBuilder: (ctx, err, st) => Container(color: Colors.grey),
)
```

---

## ✅ CHECKLIST

- [ ] Thêm `firebase_storage` và `image_picker` vào pubspec.yaml
- [ ] Chạy `flutter pub get`
- [ ] Cấu hình Firebase Storage Rules
- [ ] Thêm hàm `uploadImage()` trong firebase_service.dart
- [ ] Sửa admin_food_form_screen.dart (thêm _pickImage & upload)
- [ ] Sửa admin_categories_screen.dart (tương tự)
- [ ] Test chọn & upload ảnh
- [ ] Kiểm tra Firestore imageUrl
- [ ] Kiểm tra Firebase Storage folders

---

✅ **Hoàn thành! Ứng dụng giờ đã có đầy đủ chức năng upload ảnh!**
