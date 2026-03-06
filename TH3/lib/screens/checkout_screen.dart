import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../utils/notification_helper.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Future<UserModel?> _futureUser;
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _nameController;
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _nameController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _futureUser = _firebaseService.getUserProfile(userId);
    }
  }



  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_addressController.text.isEmpty) {
      showTopRightNotification(context, 
        'Vui lòng nhập địa chỉ giao hàng',
        isSuccess: false,
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      showTopRightNotification(context, 
        'Vui lòng nhập số điện thoại',
        isSuccess: false,
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      showTopRightNotification(context, 'Vui lòng nhập tên của bạn', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Tạo danh sách OrderItem
      final orderItems = _cart.items
          .map(
            (cartItem) => OrderItem(
              foodId: cartItem.foodId,
              foodName: cartItem.food.name,
              quantity: cartItem.quantity,
              price: cartItem.food.price,
              totalPrice: cartItem.totalPrice,
            ),
          )
          .toList();

      // Tạo đơn hàng
      final order = Order(
        id: '', // Sẽ được tạo bởi Firebase
        userId: userId,
        items: orderItems,
        totalAmount: _cart.totalPrice,
        deliveryAddress: _addressController.text,
        paymentMethod: _selectedPaymentMethod,
        status: 'pending',
        orderDate: DateTime.now(),
        userPhone: _phoneController.text,
        userName: _nameController.text,
      );

      await _firebaseService.createOrder(order);

      if (!mounted) return;

      _cart.clear();

      showTopRightNotification(context, 'Đặt hàng thành công!', isSuccess: true);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } catch (e) {
      showTopRightNotification(context, 'Lỗi: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  late Cart _cart;

  @override
  void didChangeDependencies() {
    _cart = widget.cart;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UserModel?>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            final user = snapshot.data!;
            if (_nameController.text.isEmpty) {
              _nameController.text = user.name;
              _phoneController.text = user.phone;
              _addressController.text = user.address;
            }
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin đơn hàng
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin đơn hàng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.cart.items.length,
                            itemBuilder: (context, index) {
                              final item = widget.cart.items[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.food.name} x${item.quantity}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${item.totalPrice.toStringAsFixed(0)} đ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng cộng:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.cart.totalPrice.toStringAsFixed(0)} đ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Thông tin người nhận
                  const Text(
                    'Thông tin người nhận',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Họ tên',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ giao hàng',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Phương thức thanh toán
                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Thanh toán khi nhận hàng'),
                          value: 'cash',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Chuyển khoản ngân hàng'),
                          value: 'bank',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút đặt hàng
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Xác nhận đơn hàng',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
