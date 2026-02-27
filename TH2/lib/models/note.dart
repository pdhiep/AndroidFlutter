import 'dart:convert';

class Note {
  String id;
  String title;
  String content;
  DateTime dateTime;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.dateTime,
  });

  // Chuyển Object thành Map (để chuẩn bị parse ra JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Khôi phục Object từ Map (khi đọc JSON lên)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }

  // Mã hóa List<Note> thành chuỗi JSON String
  static String encode(List<Note> notes) => json.encode(
    notes.map<Map<String, dynamic>>((note) => note.toMap()).toList(),
  );

  // Giải mã chuỗi JSON String thành List<Note>
  static List<Note> decode(String notes) =>
      (json.decode(notes) as List<dynamic>)
          .map<Note>((item) => Note.fromMap(item))
          .toList();
}
