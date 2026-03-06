import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<UserModel>> _futureUsers;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _futureUsers = _firebaseService.getAllUsers();
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      if (user.isActive) {
        await _firebaseService.blockUser(user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khóa tài khoản thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _firebaseService.unblockUser(user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mở khóa tài khoản thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() => _loadUsers());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin người dùng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('UID:', user.uid),
              _buildDetailRow(
                'Tên:',
                user.name.isEmpty ? 'Chưa cập nhật' : user.name,
              ),
              _buildDetailRow('Email:', user.email),
              _buildDetailRow(
                'Số điện thoại:',
                user.phone.isEmpty ? 'Chưa cập nhật' : user.phone,
              ),
              _buildDetailRow(
                'Địa chỉ:',
                user.address.isEmpty ? 'Chưa cập nhật' : user.address,
                maxLines: 3,
              ),
              _buildDetailRow(
                'Vai trò:',
                user.role == 'admin' ? 'Quản trị viên' : 'Khách hàng',
              ),
              _buildDetailRow(
                'Trạng thái:',
                user.isActive ? 'Hoạt động' : 'Bị khóa',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có người dùng nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: user.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    user.name.isEmpty ? user.email : user.name,
                    style: TextStyle(
                      decoration: user.isActive
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: user.isActive
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.isActive ? 'Hoạt động' : 'Bị khóa',
                          style: TextStyle(
                            fontSize: 12,
                            color: user.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Chi tiết'),
                        onTap: () => _showUserDetails(user),
                      ),
                      PopupMenuItem(
                        child: Text(
                          user.isActive ? 'Khóa' : 'Mở khóa',
                          style: TextStyle(
                            color: user.isActive ? Colors.red : Colors.green,
                          ),
                        ),
                        onTap: () => _toggleUserStatus(user),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
