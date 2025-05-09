import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../themes/app_theme.dart';
import 'adminscreen.dart';
import 'mainscreen.dart';
import 'kitchenscreen.dart';

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
        
        // Kullanıcı bilgilerini kaydet
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('userId', user['id'].toString());
        prefs.setString('userName', user['name']);
        prefs.setString('userEmail', user['email']);
        prefs.setString('userRole', role);
        
        await _saveCredentials();

        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
          );
        } else if (role == 'mutfak') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const KitchenScreen()),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // Logo alanı
                  Hero(
                    tag: 'logo',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Uygulama adı
                  const Text(
                    'DigiAdi',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Alt slogan
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Restoran Yönetim Sistemi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Form kartı
                  FadeTransition(
                    opacity: _animation,
                    child: Container(
                      width: 500,
                      constraints: const BoxConstraints(maxWidth: 500),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Form başlığı
                            Row(
                              children: [
                                Icon(
                                  _isLoginMode
                                      ? Icons.login
                                      : Icons.verified_user,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isLoginMode ? 'Giriş Yap' : 'Admin Kaydı',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Ad Soyad alanı (sadece kayıt modunda)
                            if (!_isLoginMode) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: AppTheme.inputDecoration(
                                  labelText: 'Ad Soyad',
                                  prefixIcon: Icons.person,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            // E-posta alanı
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: AppTheme.inputDecoration(
                                labelText: 'E-posta',
                                prefixIcon: Icons.mail,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Şifre alanı
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: AppTheme.inputDecoration(
                                labelText: 'Şifre',
                                prefixIcon: Icons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            // Şifre onay ve admin kodu alanları (sadece kayıt modunda)
                            if (!_isLoginMode) ...[
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: AppTheme.inputDecoration(
                                  labelText: 'Şifre Onayı',
                                  prefixIcon: Icons.lock,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _adminCodeController,
                                decoration: AppTheme.inputDecoration(
                                  labelText: 'Admin Kodu',
                                  prefixIcon: Icons.verified_user,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Beni hatırla seçeneği (sadece giriş modunda)
                            if (_isLoginMode)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppTheme.primaryColor,
                                      onChanged: (value) {
                                        setState(() => _rememberMe = value!);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Beni Hatırla',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),
                            // Giriş / Kayıt butonu
                            SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                style: AppTheme.elevatedButtonStyle,
                                onPressed: _isLoading
                                    ? null
                                    : () => _isLoginMode
                                        ? _handleLogin()
                                        : _handleSignup(),
                                icon: _isLoading
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child:
                                            const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Icon(
                                        _isLoginMode
                                            ? Icons.login
                                            : Icons.person_add,
                                        color: Colors.white,
                                      ),
                                label: Text(
                                  _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Mod değiştirme butonu
                            Center(
                              child: TextButton(
                                onPressed: _toggleMode,
                                child: Text.rich(
                                  TextSpan(
                                    text: _isLoginMode
                                        ? 'Henüz bir hesabın yok mu? '
                                        : 'Zaten bir hesabın var mı? ',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _isLoginMode
                                            ? 'Admin hesabı oluştur'
                                            : 'Giriş yap',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}