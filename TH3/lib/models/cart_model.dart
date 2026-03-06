import 'food_model.dart';

class CartItem {
  final String foodId;
  final Food food;
  int quantity;

  CartItem({required this.foodId, required this.food, required this.quantity});

  double get totalPrice => food.price * quantity;

  CartItem copyWith({String? foodId, Food? food, int? quantity}) {
    return CartItem(
      foodId: foodId ?? this.foodId,
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Cart {
  List<CartItem> items;

  Cart({this.items = const []}) {
    items = List.from(items);
  }

  void addItem(Food food) {
    final existingItem = items.firstWhere(
      (item) => item.foodId == food.id,
      orElse: () => CartItem(foodId: food.id, food: food, quantity: 0),
    );

    if (existingItem.quantity == 0) {
      items.add(CartItem(foodId: food.id, food: food, quantity: 1));
    } else {
      existingItem.quantity++;
    }
  }

  void removeItem(String foodId) {
    items.removeWhere((item) => item.foodId == foodId);
  }

  void updateQuantity(String foodId, int quantity) {
    final item = items.firstWhere((item) => item.foodId == foodId);
    if (quantity <= 0) {
      removeItem(foodId);
    } else {
      item.quantity = quantity;
    }
  }

  void clear() {
    items.clear();
  }

  double get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get itemCount => items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}
