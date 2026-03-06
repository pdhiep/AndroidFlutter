import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'services/firebase_service.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Đặt Đồ Ăn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return UserRoleChecker(user: snapshot.data!);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class UserRoleChecker extends StatelessWidget {
  final User user;
  late final FirebaseService _firebaseService;

  UserRoleChecker({super.key, required this.user}) {
    _firebaseService = FirebaseService();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _firebaseService.getUserProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Lỗi: ${snapshot.error}')));
        }

        if (snapshot.data == null) {
          return const HomeScreen();
        }

        final userProfile = snapshot.data!;
        final role = userProfile.role.toLowerCase().trim();

        print('DEBUG: User role = "$role" (admin=${role == 'admin'})');

        if (role == 'admin') {
          return const AdminHomeScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
