import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_manage_foods_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Phạm Đức Hiệp - 2251161997",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildAdminCard(
            context,
            Icons.fastfood,
            'Quản lý Món ăn',
            Colors.orange,
            'food',
          ),
          _buildAdminCard(
            context,
            Icons.category,
            'Quản lý Danh mục',
            Colors.blue,
            'category',
          ),
          _buildAdminCard(
            context,
            Icons.receipt_long,
            'Quản lý Đơn hàng',
            Colors.green,
            'order',
          ),
          _buildAdminCard(
            context,
            Icons.people,
            'Quản lý Khách hàng',
            Colors.purple,
            'user',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String type,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Widget screen;
          switch (type) {
            case 'food':
              screen = const AdminManageFoodsScreen();
              break;
            case 'category':
              screen = const AdminCategoriesScreen();
              break;
            case 'order':
              screen = const AdminOrdersScreen();
              break;
            case 'user':
              screen = const AdminUsersScreen();
              break;
            default:
              screen = const AdminHomeScreen();
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
