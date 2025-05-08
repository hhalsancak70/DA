import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'adminscreen.dart';
import 'mainscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _adminCodeController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      prefs.setBool('rememberMe', true);
      prefs.setString('email', _emailController.text.trim());
      prefs.setString('password', _passwordController.text.trim());
    } else {
      prefs.remove('rememberMe');
      prefs.remove('email');
      prefs.remove('password');
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _confirmPasswordController.clear();
      _adminCodeController.clear();
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen email ve şifre girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uri = Uri.parse('http://10.0.2.2:3000/auth/login');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['user'];
        final role = user['role'];
        await _saveCredentials();

        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        final error = json.decode(response.body)['error'] ?? 'Giriş başarısız';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sunucuya bağlanılamadı')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty ||
        _adminCodeController.text.trim() != 'admin123') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tüm alanları doldurun ve doğru admin kodunu girin')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreler eşleşmiyor')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uri = Uri.parse('http://10.0.2.2:3000/auth/register');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': 'admin',
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı. Giriş yapabilirsiniz')),
        );
        _toggleMode();
      } else {
        final error = json.decode(response.body)['error'] ?? 'Kayıt başarısız';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sunucuya bağlanılamadı')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7E5F), Color(0xFFFFA07A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant_menu,
                      size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DigiAdi',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Restoran Yönetim Sistemi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 500,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                                _isLoginMode
                                    ? Icons.login
                                    : Icons.verified_user,
                                color: const Color(0xFFFF7E5F)),
                            const SizedBox(width: 8),
                            Text(
                              _isLoginMode ? 'Giriş Yap' : 'Admin Kaydı',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF7E5F)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (!_isLoginMode) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Ad Soyad',
                              prefixIcon: const Icon(Icons.person,
                                  color: Color(0xFFFF7E5F)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            prefixIcon: const Icon(Icons.mail,
                                color: Color(0xFFFF7E5F)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: const Icon(Icons.lock,
                                color: Color(0xFFFF7E5F)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey),
                              onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        if (!_isLoginMode) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Şifre Onayı',
                              prefixIcon: const Icon(Icons.lock,
                                  color: Color(0xFFFF7E5F)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey),
                                onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                !_obscureConfirmPassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _adminCodeController,
                            decoration: InputDecoration(
                              labelText: 'Admin Kodu',
                              prefixIcon: const Icon(Icons.verified_user,
                                  color: Color(0xFFFF7E5F)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (_isLoginMode)
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value!;
                                  });
                                },
                              ),
                              const Text('Beni Hatırla',
                                  style: TextStyle(color: Colors.black87)),
                            ],
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7E5F),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _isLoginMode
                                ? _handleLogin()
                                : _handleSignup(),
                            icon: Icon(
                                _isLoginMode ? Icons.login : Icons.person_add,
                                color: Colors.white),
                            label: _isLoading
                                ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                                : Text(_isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _toggleMode,
                            child: Text.rich(
                              TextSpan(
                                text: _isLoginMode
                                    ? 'Henüz bir hesabın yok mu? '
                                    : 'Zaten bir hesabın var mı? ',
                                style: const TextStyle(color: Colors.black54),
                                children: [
                                  TextSpan(
                                    text: _isLoginMode
                                        ? 'Admin hesabı oluştur'
                                        : 'Giriş yap',
                                    style: const TextStyle(
                                        color: Color(0xFFFF7E5F),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}