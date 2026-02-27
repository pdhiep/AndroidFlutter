import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Nối với màn hình chính

void main() {
  runApp(const SmartNoteApp());
}

class SmartNoteApp extends StatelessWidget {
  const SmartNoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Note',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor:
            Colors.grey[200], // Nền xám nhạt để nổi thẻ Card
      ),
      home: const HomeScreen(), // Trang đầu tiên khi mở app
    );
  }
}
