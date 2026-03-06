class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String address;
  final String role; // 'user' or 'admin'
  final bool isActive; // false if account is blocked
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    // Xử lý phone an toàn - có thể là int, string, hoặc null
    String phone = '';
    final phoneData = data['phone'];
    if (phoneData != null) {
      if (phoneData is String) {
        phone = phoneData;
      } else if (phoneData is int) {
        phone = phoneData.toString();
      } else {
        phone = phoneData.toString();
      }
    }

    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: phone,
      address: data['address'] ?? '',
      role: (data['role'] ?? 'user')
          .toString()
          .toLowerCase()
          .trim(), // Ensure string
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? address,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
