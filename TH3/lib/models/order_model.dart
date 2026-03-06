class OrderItem {
  final String foodId;
  final String foodName;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      foodId: data['foodId'] ?? '',
      foodName: data['foodName'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'quantity': quantity,
      'price': price,
      'totalPrice': totalPrice,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String deliveryAddress;
  final String paymentMethod;
  final String status; // pending, confirmed, shipping, delivered, cancelled
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String userPhone;
  final String userName;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.userPhone,
    required this.userName,
  });

  factory Order.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<OrderItem> orderItems = [];
    if (data['items'] != null) {
      orderItems = (data['items'] as List)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: documentId,
      userId: data['userId'] ?? '',
      items: orderItems,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      status: data['status'] ?? 'pending',
      orderDate: data['orderDate'] != null
          ? (data['orderDate'] as dynamic).toDate()
          : DateTime.now(),
      deliveryDate: data['deliveryDate'] != null
          ? (data['deliveryDate'] as dynamic).toDate()
          : null,
      userPhone: data['userPhone'] ?? '',
      userName: data['userName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'status': status,
      'orderDate': orderDate,
      'deliveryDate': deliveryDate,
      'userPhone': userPhone,
      'userName': userName,
    };
  }
}
