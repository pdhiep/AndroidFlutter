import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  bool simulateError = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== AUTHENTICATION ====================
  Future<void> registerAndCreateProfile(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'name': name,
        'role': 'user',
        'phone': '',
        'address': '',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception("Sai email hoặc mật khẩu!");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Lỗi gửi email đặt lại mật khẩu: $e");
    }
  }

  // ==================== CREATE ADMIN ====================
  Future<void> createAdminAccount(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'name': name,
        'role': 'admin', // ← ADMIN ROLE
        'phone': '',
        'address': '',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==================== USER PROFILE ====================
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception("Lỗi tải hồ sơ: $e");
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': user.name,
        'phone': user.phone,
        'address': user.address,
      });
    } catch (e) {
      throw Exception("Lỗi cập nhật hồ sơ: $e");
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("Người dùng không tồn tại!");

      // Xác thực lại với mật khẩu cũ
      var credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception("Lỗi thay đổi mật khẩu: $e");
    }
  }

  // ==================== CATEGORIES ====================
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      if (simulateError) throw Exception("Mất kết nối mạng!");
      QuerySnapshot snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map(
            (doc) => CategoryModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception("Lỗi tải danh mục: $e");
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      await _firestore.collection('categories').add({
        'name': category.name,
        'imageUrl': category.imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Lỗi thêm danh mục: $e");
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _firestore.collection('categories').doc(category.id).update({
        'name': category.name,
        'imageUrl': category.imageUrl,
      });
    } catch (e) {
      throw Exception("Lỗi cập nhật danh mục: $e");
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      throw Exception("Lỗi xóa danh mục: $e");
    }
  }

  // ==================== FOODS ====================
  Future<List<Food>> fetchFoods({
    String categoryId = '',
    String searchQuery = '',
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (simulateError) throw Exception("Mất kết nối mạng!");

      Query query = _firestore.collection('foods');

      // Chỉ dùng 1 where clause để tránh Firestore index error
      // Lọc theo categoryId nếu có
      if (categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      QuerySnapshot snapshot = await query.get();
      List<Food> foods = snapshot.docs
          .map(
            (doc) =>
                Food.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Lọc by price range (in-app filtering)
      if (minPrice != null) {
        foods = foods.where((food) => food.price >= minPrice).toList();
      }

      if (maxPrice != null) {
        foods = foods.where((food) => food.price <= maxPrice).toList();
      }

      // Filter by search query (in-app search)
      if (searchQuery.isNotEmpty) {
        foods = foods
            .where(
              (food) =>
                  food.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  food.description.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }

      return foods;
    } catch (e) {
      throw Exception("Lỗi tải món ăn: $e");
    }
  }

  Future<Food?> getFoodById(String foodId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('foods')
          .doc(foodId)
          .get();
      if (!doc.exists) return null;
      return Food.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception("Lỗi tải chi tiết món ăn: $e");
    }
  }

  Future<void> addFood(Food food) async {
    try {
      await _firestore.collection('foods').add({
        'name': food.name,
        'description': food.description,
        'price': food.price,
        'imageUrl': food.imageUrl,
        'categoryId': food.categoryId,
        'rating': food.rating,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Lỗi thêm món ăn: $e");
    }
  }

  Future<void> updateFood(Food food) async {
    try {
      await _firestore.collection('foods').doc(food.id).update({
        'name': food.name,
        'description': food.description,
        'price': food.price,
        'imageUrl': food.imageUrl,
        'categoryId': food.categoryId,
        'rating': food.rating,
      });
    } catch (e) {
      throw Exception("Lỗi cập nhật món ăn: $e");
    }
  }

  Future<void> deleteFood(String foodId) async {
    try {
      await _firestore.collection('foods').doc(foodId).delete();
    } catch (e) {
      throw Exception("Lỗi xóa món ăn: $e");
    }
  }

  // ==================== ORDERS ====================
  Future<String> createOrder(Order order) async {
    try {
      DocumentReference docRef = await _firestore.collection('orders').add({
        'userId': order.userId,
        'items': order.items.map((item) => item.toMap()).toList(),
        'totalAmount': order.totalAmount,
        'deliveryAddress': order.deliveryAddress,
        'paymentMethod': order.paymentMethod,
        'status': 'pending',
        'orderDate': FieldValue.serverTimestamp(),
        'userPhone': order.userPhone,
        'userName': order.userName,
      });
      return docRef.id;
    } catch (e) {
      throw Exception("Lỗi tạo đơn hàng: $e");
    }
  }

  Future<List<Order>> getUserOrders(String userId) async {
    try {
      // Chỉ filter userId trên Firestore (không cần index)
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      List<Order> orders = snapshot.docs
          .map(
            (doc) =>
                Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Sắp xếp by orderDate in-app (client-side)
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      return orders;
    } catch (e) {
      throw Exception("Lỗi tải đơn hàng: $e");
    }
  }

  Future<List<Order>> getAllOrders() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('orders').get();

      List<Order> orders = snapshot.docs
          .map(
            (doc) =>
                Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Sắp xếp by orderDate in-app (mới nhất trước)
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      return orders;
    } catch (e) {
      throw Exception("Lỗi tải danh sách đơn hàng: $e");
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();
      if (!doc.exists) return null;
      return Order.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception("Lỗi tải chi tiết đơn hàng: $e");
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        if (newStatus == 'delivered')
          'deliveryDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Lỗi cập nhật trạng thái đơn: $e");
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      throw Exception("Lỗi hủy đơn hàng: $e");
    }
  }

  // ==================== USER MANAGEMENT (ADMIN) ====================
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      List<UserModel> users = snapshot.docs
          .map(
            (doc) => UserModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // Sắp xếp by createdAt in-app (mới nhất trước)
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return users;
    } catch (e) {
      throw Exception("Lỗi tải danh sách người dùng: $e");
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception("Lỗi khóa tài khoản: $e");
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
      });
    } catch (e) {
      throw Exception("Lỗi mở khóa tài khoản: $e");
    }
  }

  // ==================== STATISTICS ====================
  Future<int> getTotalOrders() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('orders').get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<double> getTotalRevenue() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('orders').get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc['totalAmount'] ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }
}
