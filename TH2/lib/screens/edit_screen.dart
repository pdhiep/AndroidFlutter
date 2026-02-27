import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class EditScreen extends StatefulWidget {
  final Note? existingNote;

  const EditScreen({Key? key, this.existingNote}) : super(key: key);

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
  }

  // Hàm xử lý khi người dùng ấn Back (Auto-save)
  Future<void> _handleAutoSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Nếu cả 2 ô đều trống thì không làm gì cả
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context, null); // Trả về null
      return;
    }

    // Tạo đối tượng Note mới hoặc cập nhật Note cũ
    final savedNote = Note(
      id: widget.existingNote?.id ?? DateTime.now().toString(),
      title: title.isEmpty ? 'Không có tiêu đề' : title,
      content: content,
      dateTime: DateTime.now(), // Luôn cập nhật thời gian mới nhất
    );

    // Lưu trực tiếp vào SharedPreferences (mã hóa JSON)
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notesString = prefs.getString('notes_data');
      List<Note> notes = [];
      if (notesString != null) {
        notes = Note.decode(notesString);
      }

      final index = notes.indexWhere((n) => n.id == savedNote.id);
      if (index != -1) {
        notes[index] = savedNote;
      } else {
        notes.insert(0, savedNote);
      }
      // Sắp xếp mới nhất lên đầu
      notes.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      await prefs.setString('notes_data', Note.encode(notes));
    } catch (_) {
      // Nếu có lỗi lưu, vẫn pop với savedNote để Home xử lý thay thế
    }

    // Thoát màn hình và mang theo cục dữ liệu về màn hình chính
    if (!mounted) return;
    Navigator.pop(context, savedNote);
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope dùng để chặn sự kiện ấn nút Back hệ thống
    return WillPopScope(
      onWillPop: () async {
        await _handleAutoSave(); // Đợi lưu hoàn tất trước khi tiếp tục
        return false; // Ngăn pop mặc định vì đã pop trong _handleAutoSave
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Giao diện tối giản
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              await _handleAutoSave(); // Đợi lưu trước khi rời
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Ô Tiêu đề
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: "Tiêu đề",
                  border: InputBorder.none, // Ẩn viền
                ),
                maxLines: null, // Nhập đa dòng
              ),
              const SizedBox(height: 10),
              // Ô Nội dung
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: "Nhập nội dung ghi chú...",
                    border: InputBorder.none, // Ẩn viền
                  ),
                  maxLines: null, // Tự giãn chiều cao
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
