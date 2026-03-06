import 'package:flutter/material.dart';
import '../../../models/food_model.dart';
import '../../../services/firebase_service.dart';
import 'admin_food_form_screen.dart';

class AdminManageFoodsScreen extends StatefulWidget {
  const AdminManageFoodsScreen({super.key});

  @override
  State<AdminManageFoodsScreen> createState() => _AdminManageFoodsScreenState();
}

class _AdminManageFoodsScreenState extends State<AdminManageFoodsScreen> {
  final FirebaseService _apiService = FirebaseService();
  late Future<List<Food>> _futureFoods;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureFoods = _apiService.fetchFoods(); // Tải tất cả món
    });
  }

  Future<void> _deleteFood(Food food) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text('Bạn có chắc muốn xóa món "${food.name}" không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _apiService.deleteFood(food.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa thành công!')));
        _loadData(); // Tải lại danh sách
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Món ăn'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Food>>(
        future: _futureFoods,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(child: Text("Chưa có món ăn nào."));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final food = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Image.network(
                    food.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.fastfood),
                  ),
                  title: Text(
                    food.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${food.price.toStringAsFixed(0)} đ'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          // Mở form Sửa
                          bool? needRefresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminFoodFormScreen(existingFood: food),
                            ),
                          );
                          if (needRefresh == true) _loadData();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFood(food), // Gọi hàm Xóa
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          // Mở form Thêm mới
          bool? needRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminFoodFormScreen()),
          );
          if (needRefresh == true) _loadData();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
