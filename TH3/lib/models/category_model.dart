class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;

  CategoryModel({required this.id, required this.name, required this.imageUrl});

  factory CategoryModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return CategoryModel(
      id: documentId,
      name: data['name'] ?? 'Chưa có tên',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
