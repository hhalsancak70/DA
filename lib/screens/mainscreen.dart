import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../themes/app_theme.dart';
import 'loginscreen.dart';
import 'ordersscreen.dart';
import 'tablesscreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  String waiterName = 'Garson';
  String waiterEmail = '';
  String userId = '';
  String role = '';
  late AnimationController _controller;
  late Animation<double> _animation;
  
  // Profil düzenleme için controller'lar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      waiterName = prefs.getString('userName') ?? 'Garson';
      waiterEmail = prefs.getString('userEmail') ?? '';
      userId = prefs.getString('userId') ?? '';
      role = prefs.getString('userRole') ?? '';
      
      // Controller'ları güncelle
      _nameController.text = waiterName;
      _emailController.text = waiterEmail;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Kullanıcı bilgilerini güncelleme
  Future<void> _updateUserProfile() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      _showMessage('Lütfen isim ve e-posta alanlarını doldurun');
      return;
    }
    
    // Yeni şifre girilmişse kontrol et
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showMessage('Şifreler eşleşmiyor');
        return;
      }
      if (_passwordController.text.length < 6) {
        _showMessage('Şifre en az 6 karakter olmalıdır');
        return;
      }
    }
    
    setState(() => _isLoading = true);
    
    // Güncelleme verisini hazırla
    final Map<String, dynamic> updateData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
    };
    
    // Eğer şifre girilmişse ekle
    if (_passwordController.text.isNotEmpty) {
      updateData['password'] = _passwordController.text;
    }
    
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      
      if (response.statusCode == 200) {
        // Başarıyla güncellendi, SharedPreferences'ı güncelle
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('userName', _nameController.text.trim());
        prefs.setString('userEmail', _emailController.text.trim());
        
        setState(() {
          waiterName = _nameController.text.trim();
          waiterEmail = _emailController.text.trim();
        });
        
        _showMessage('Profil bilgileriniz güncellendi', success: true);
        Navigator.of(context).pop(); // Diyaloğu kapat
        
        // Şifreleri temizle
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        final error = json.decode(response.body)['error'] ?? 'Güncelleme başarısız';
        _showMessage(error);
      }
    } catch (e) {
      _showMessage('Sunucuya bağlanılamadı');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('Profil Düzenle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İsim alanı
                  TextField(
                    controller: _nameController,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'İsim',
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // E-posta alanı
                  TextField(
                    controller: _emailController,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  
                  // Şifre alanı (isteğe bağlı)
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'Yeni Şifre (isteğe bağlı)',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Şifre onay alanı
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'Şifre Onay',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Kaydet'),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    );
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return FadeTransition(
      opacity: _animation,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon, 
                        size: 42, 
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst başlık alanı
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Hero(
                          tag: 'logo',
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FadeTransition(
                          opacity: _animation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DigiAdi',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hoş geldin, $waiterName!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.logout,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          onPressed: () => _handleLogout(context),
                          tooltip: 'Çıkış Yap',
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showEditProfileDialog,
                          borderRadius: BorderRadius.circular(40),
                          child: Ink(
                            child: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              radius: 20,
                              child: Text(
                                waiterName.isNotEmpty ? waiterName[0].toUpperCase() : 'G',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Ana içerik alanı
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.dashboard_customize,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hızlı Erişim',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                          children: [
                            _buildCard(
                              'Masalar',
                              Icons.table_bar,
                              AppTheme.primaryColor,
                              () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const TablesScreen())),
                            ),
                            _buildCard(
                              'Siparişler',
                              Icons.receipt_long,
                              AppTheme.successColor,
                              () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const OrdersScreen())),
                            ),
                            // Diğer hızlı erişim kartları
                            _buildCard(
                              'Günlük Özet',
                              Icons.analytics,
                              Colors.indigo,
                              () => _showFeatureUnderDevelopment(context),
                            ),
                            _buildCard(
                              'Ayarlar',
                              Icons.settings,
                              Colors.blueGrey,
                              () => _showFeatureUnderDevelopment(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showFeatureUnderDevelopment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bu özellik henüz geliştirme aşamasındadır.'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (!mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}
