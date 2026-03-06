import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../utils/notification_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _auth() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      showTopRightNotification(context, 'Vui lòng nhập email và mật khẩu', isSuccess: false);
      return;
    }

    if (!_isLogin && _name.text.isEmpty) {
      showTopRightNotification(context, 'Vui lòng nhập tên', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseService = FirebaseService();

      if (_isLogin) {
        await firebaseService.login(_email.text.trim(), _pass.text.trim());
        if (mounted) {
          showTopRightNotification(context, 'Đăng nhập thành công');
        }
      } else {
        await firebaseService.registerAndCreateProfile(
          _email.text.trim(),
          _pass.text.trim(),
          _name.text.trim(),
        );
        if (mounted) {
          setState(() => _isLogin = true);
          _email.clear();
          _pass.clear();
          _name.clear();
          showTopRightNotification(context, 'Đăng ký thành công! Vui lòng đăng nhập.');
        }
      }
    } catch (e) {
      if (mounted) {
        showTopRightNotification(context, e.toString(), isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPassword() {
    if (_email.text.isEmpty) {
      showTopRightNotification(context, 'Vui lòng nhập email', isSuccess: false);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: Text(
          'Email để đặt lại mật khẩu sẽ được gửi đến ${_email.text}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: _email.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  showTopRightNotification(context, 'Kiểm tra email để đặt lại mật khẩu');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  showTopRightNotification(context, 'Lỗi: $e', isSuccess: false);
                }
              }
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.fastfood, size: 80, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  "Đặt Đồ Ăn",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 40),
                if (!_isLogin)
                  Column(
                    children: [
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: "Họ tên",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pass,
                  decoration: const InputDecoration(
                    labelText: "Mật khẩu",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _auth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Hoặc',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLogin)
                  Column(
                    children: [
                      TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() => _isLogin = false);
                          _pass.clear();
                          _email.clear();
                        },
                        child: const Text(
                          'Tạo tài khoản mới',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  )
                else
                  TextButton(
                    onPressed: () {
                      setState(() => _isLogin = true);
                      _pass.clear();
                      _email.clear();
                      _name.clear();
                    },
                    child: const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _name.dispose();
    super.dispose();
  }
}
