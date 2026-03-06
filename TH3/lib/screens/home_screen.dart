import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_model.dart';
import '../models/category_model.dart';
import '../models/cart_model.dart';
import '../services/firebase_service.dart';
import 'food_detail_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'order_tracking_screen.dart';
import '../utils/notification_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<CategoryModel>> _futureCategories;
  late Future<List<Food>> _futureFoods;
  final FirebaseService _apiService = FirebaseService();
  final Cart _cart = Cart();

  String _selectedCategoryId = '';
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureCategories = _apiService.fetchCategories();
      _futureFoods = _apiService.fetchFoods(
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
    });
  }

  void _selectCategory(String id) {
    setState(() {
      _selectedCategoryId = id;
      _loadData();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final minController = TextEditingController(
          text: _minPrice?.toString() ?? '',
        );
        final maxController = TextEditingController(
          text: _maxPrice?.toString() ?? '',
        );

        return AlertDialog(
          title: const Text('Lọc theo giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá tối thiểu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá tối đa',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _minPrice = minController.text.isEmpty
                      ? null
                      : double.tryParse(minController.text);
                  _maxPrice = maxController.text.isEmpty
                      ? null
                      : double.tryParse(maxController.text);
                  _loadData();
                });
                Navigator.pop(context);
              },
              child: const Text('Áp dụng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Đặt Đồ Ăn Online',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${_cart.itemCount}'),
              isLabelVisible: _cart.itemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(cart: _cart),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderTrackingScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _loadData();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.orange),
                  onPressed: _showFilterDialog,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Category filter
          SizedBox(
            height: 60,
            child: FutureBuilder<List<CategoryModel>>(
              future: _futureCategories,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final categories = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    bool isAll = index == 0;
                    String cId = isAll ? '' : categories[index - 1].id;
                    String cName = isAll
                        ? 'Tất cả'
                        : categories[index - 1].name;
                    bool isSelected = _selectedCategoryId == cId;

                    return GestureDetector(
                      onTap: () => _selectCategory(cId),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Text(
                          cName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Food list
          Expanded(
            child: FutureBuilder<List<Food>>(
              future: _futureFoods,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          snapshot.error.toString().replaceAll(
                            "Exception: ",
                            "",
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final food = snapshot.data![index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FoodDetailScreen(food: food),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Hình ảnh bên trái
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey[200],
                                    child: Image.network(
                                      food.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, st) =>
                                          Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.fastfood,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Thông tin ở giữa
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Tên món
                                      Text(
                                        food.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Mô tả
                                      Text(
                                        food.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      // Rating và Giá
                                      Row(
                                        children: [
                                          // Rating
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                food.rating.toString(),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          // Giá
                                          Text(
                                            '${food.price.toStringAsFixed(0)} đ',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Nút Add to Cart bên phải
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _cart.addItem(food);
                                        });
                                        showTopRightNotification(
                                            context,
                                            '${food.name} đã được thêm vào giỏ');
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(
                  child: Text("Không có món ăn nào phù hợp."),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
