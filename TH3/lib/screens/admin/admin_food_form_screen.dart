import 'package:flutter/material.dart';
import '../../../models/food_model.dart';
import '../../../models/category_model.dart';
import '../../../services/firebase_service.dart';

class AdminFoodFormScreen extends StatefulWidget {
  final Food? existingFood; // Truyền vào nếu là Sửa món

  const AdminFoodFormScreen({super.key, this.existingFood});

  @override
  State<AdminFoodFormScreen> createState() => _AdminFoodFormScreenState();
}

class _AdminFoodFormScreenState extends State<AdminFoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = FirebaseService();

  late TextEditingController _nameCtrl,
      _descCtrl,
      _priceCtrl,
      _imageCtrl,
      _ratingCtrl;
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final f = widget.existingFood;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _descCtrl = TextEditingController(text: f?.description ?? '');
    _priceCtrl = TextEditingController(text: f?.price.toStringAsFixed(0) ?? '');
    _imageCtrl = TextEditingController(text: f?.imageUrl ?? '');
    _ratingCtrl = TextEditingController(text: f?.rating.toString() ?? '5.0');
    _selectedCategoryId = f?.categoryId;

    _loadCategories();
  }

  // Tải danh mục để cho vào Dropdown
  Future<void> _loadCategories() async {
    try {
      final cats = await _apiService.fetchCategories();
      setState(() => _categories = cats);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đủ thông tin và chọn danh mục'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newFood = Food(
        id:
            widget.existingFood?.id ??
            '', // Sẽ được Firebase tự tạo nếu là Thêm mới
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        imageUrl: _imageCtrl.text.trim(),
        categoryId: _selectedCategoryId!,
        rating: double.parse(_ratingCtrl.text.trim()),
      );

      if (widget.existingFood == null) {
        await _apiService.addFood(newFood);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm món thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _apiService.updateFood(newFood);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true); // Quay lại và báo thành công
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingFood != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa món ăn' : 'Thêm món ăn mới'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên món ăn',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Giá tiền (VNĐ)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Lỗi' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ratingCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Đánh giá (1-5)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Lỗi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _categories.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Chọn danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategoryId = val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link ảnh (URL)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Không được để trống' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_imageCtrl.text.isNotEmpty)
                      Image.network(
                        _imageCtrl.text,
                        height: 150,
                        errorBuilder: (c, e, s) => const Text('Ảnh lỗi'),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saveFood,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'LƯU MÓN ĂN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
