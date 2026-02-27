import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes(); // Đọc dữ liệu khi khởi động
  }

  // Đọc dữ liệu từ thiết bị
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesString = prefs.getString('notes_data');
    if (notesString != null) {
      setState(() {
        _notes = Note.decode(notesString);
        // Sắp xếp: Ghi chú mới nhất lên đầu
        _notes.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      });
    }
  }

  // Lưu dữ liệu xuống thiết bị
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = Note.encode(_notes);
    await prefs.setString('notes_data', encodedData);
  }

  // Lọc ghi chú theo tìm kiếm (Real-time)
  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    return _notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Chuyển sang màn hình soạn thảo
  Future<void> _navigateToEditScreen([Note? note]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditScreen(existingNote: note)),
    );

    // Xử lý dữ liệu trả về (khi người dùng bấm Back ở màn hình Edit)
    if (result != null && result is Note) {
      setState(() {
        int index = _notes.indexWhere((element) => element.id == result.id);
        if (index != -1) {
          _notes[index] = result; // Cập nhật ghi chú cũ
        } else {
          _notes.insert(0, result); // Thêm ghi chú mới lên đầu
        }
        // Sắp xếp lại danh sách
        _notes.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      });
      _saveNotes(); // Lưu lại ngay lập tức
    }
  }

  // Hàm xóa ghi chú (không có undo)
  // (Removed unused helper _deleteNote to avoid analyzer warning)

  // Xóa với Undo snackbar
  void _performDeleteWithUndo(Note note) {
    final removedIndex = _notes.indexWhere((element) => element.id == note.id);
    if (removedIndex == -1) return;

    final removedNote = _notes[removedIndex];
    setState(() {
      _notes.removeAt(removedIndex);
    });
    _saveNotes();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã xóa ghi chú'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () {
            setState(() {
              // Nếu danh sách rỗng hoặc index vượt quá, thêm vào đầu
              final insertIndex = removedIndex <= _notes.length
                  ? removedIndex
                  : 0;
              _notes.insert(insertIndex, removedNote);
            });
            _saveNotes();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Hộp thoại xác nhận xóa
  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Trả về false
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Trả về true
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Note - [Phạm Đức Hiệp] - [2251161997]',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ghi chú...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none, // Bỏ viền
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value; // Cập nhật từ khóa liên tục
                });
              },
            ),
          ),

          // Danh sách ghi chú
          Expanded(
            child: _filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: 0.3,
                          child: SvgPicture.asset(
                            'assets/empty.svg',
                            width: 140,
                            height: 140,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Bạn chưa có ghi chú nào,\nhãy tạo mới nhé!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : MasonryGridView.count(
                    // Dùng thư viện Staggered Grid
                    crossAxisCount: 2, // 2 cột
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.endToStart, // Vuốt trái
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) => _confirmDelete(),
                        onDismissed: (direction) =>
                            _performDeleteWithUndo(note),
                        child: GestureDetector(
                          onTap: () => _navigateToEditScreen(note),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    note.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note.content,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(note.dateTime),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditScreen(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
