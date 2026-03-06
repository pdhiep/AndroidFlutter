class Food {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId; // Đã bổ sung trường này để Lọc món
  final double rating; // Đã bổ sung trường này để chấm Điểm

  Food({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.rating,
  });

  // Chuyển đổi dữ liệu từ Map của Firebase sang Đối tượng Food
  factory Food.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Xử lý price an toàn - có thể là double, int, hoặc string
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

    // Xử lý rating an toàn
    double rating = 5.0;
    try {
      final ratingData = data['rating'] ?? 5.0;
      if (ratingData is double) {
        rating = ratingData;
      } else if (ratingData is int) {
        rating = ratingData.toDouble();
      }
    } catch (e) {
      rating = 5.0;
    }

    return Food(
      id: documentId,
      name: data['name'] ?? 'Món ăn chưa có tên',
      description: data['description'] ?? 'Chưa có mô tả chi tiết',
      price: price,
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
      categoryId: data['categoryId'] ?? '',
      rating: rating,
    );
  }
}
