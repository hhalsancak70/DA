import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../themes/app_theme.dart';
import 'loginscreen.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({Key? key}) : super(key: key);

  @override
  _KitchenScreenState createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = false;
  String _userName = 'Mutfak';
  String _userEmail = '';
  String _userId = '';
  Timer? _refreshTimer;
  Map<int, Duration> _orderDurations = {};
  final Map<int, Timer> _orderTimers = {};
  
  // Profil düzenleme için controller'lar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isProfileLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchOrders();
    // Her 30 saniyede bir siparişleri otomatik güncelle
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Tüm sipariş sayaçlarını temizle
    for (var timer in _orderTimers.values) {
      timer.cancel();
    }
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Mutfak';
      _userEmail = prefs.getString('userEmail') ?? '';
      _userId = prefs.getString('userId') ?? '';
      
      // Controller'ları güncelle
      _nameController.text = _userName;
      _emailController.text = _userEmail;
    });
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
    
    setState(() => _isProfileLoading = true);
    
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
        Uri.parse('http://10.0.2.2:3000/users/$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      
      if (response.statusCode == 200) {
        // Başarıyla güncellendi, SharedPreferences'ı güncelle
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('userName', _nameController.text.trim());
        prefs.setString('userEmail', _emailController.text.trim());
        
        setState(() {
          _userName = _nameController.text.trim();
          _userEmail = _emailController.text.trim();
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
      setState(() => _isProfileLoading = false);
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
                onPressed: _isProfileLoading ? null : _updateUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isProfileLoading
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

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/orders'));
      if (response.statusCode == 200) {
        // Sadece aktif ve hazır olmayan siparişleri filtrele
        final List<dynamic> allOrders = json.decode(response.body);
        final activeOrders = allOrders.where((order) => 
            (order['is_active'] == true || order['is_active'] == 1) && 
            (order['is_ready'] == false || order['is_ready'] == 0)).toList();
        
        setState(() {
          _orders = activeOrders;
          
          // Her sipariş için sayaç başlat
          for (var order in activeOrders) {
            final orderId = order['id'] as int;
            if (_orderTimers.containsKey(orderId)) continue;
            
            final createdAt = DateTime.tryParse(order['created_at'] ?? '');
            if (createdAt != null) {
              final elapsed = DateTime.now().difference(createdAt);
              _orderDurations[orderId] = elapsed;
              
              _orderTimers[orderId] = Timer.periodic(const Duration(seconds: 1), (timer) {
                setState(() {
                  _orderDurations[orderId] = _orderDurations[orderId]! + const Duration(seconds: 1);
                });
              });
            }
          }
          
          // Artık aktif olmayan siparişlerin sayaçlarını temizle
          final activeOrderIds = activeOrders.map<int>((o) => o['id'] as int).toSet();
          final timersToRemove = _orderTimers.keys.where((id) => !activeOrderIds.contains(id)).toList();
          
          for (var id in timersToRemove) {
            _orderTimers[id]?.cancel();
            _orderTimers.remove(id);
            _orderDurations.remove(id);
          }
        });
      } else {
        _showMessage('Siparişler yüklenemedi');
      }
    } catch (e) {
      _showMessage('Sunucuya bağlanılamadı');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markOrderAsReady(int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/orders/$orderId/ready'),
      );
      if (response.statusCode == 200) {
        _showMessage('Sipariş hazır olarak işaretlendi', success: true);
        
        // Sayacı durdur
        _orderTimers[orderId]?.cancel();
        _orderTimers.remove(orderId);
        _orderDurations.remove(orderId);
        
        _fetchOrders();
      } else {
        _showMessage('Güncelleme başarısız');
      }
    } catch (e) {
      _showMessage('Sunucuya bağlanılamadı');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final tableId = order['table_id'] as int;
    final orderId = order['id'] as int;
    
    // Teslim süresinin rengini hesapla (15dk geçtiyse kırmızı yap)
    final duration = _orderDurations[orderId] ?? Duration.zero;
    final isUrgent = duration.inMinutes >= 15;
    final durationColor = isUrgent ? AppTheme.errorColor : AppTheme.textPrimary;
    final durationBgColor = isUrgent ? Colors.red.shade50 : Colors.blue.shade50;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isUrgent 
              ? AppTheme.errorColor.withOpacity(0.3) 
              : Colors.grey.shade200,
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sipariş başlık alanı
            Container(
              decoration: BoxDecoration(
                color: isUrgent 
                    ? AppTheme.errorColor.withOpacity(0.1) 
                    : Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: isUrgent
                        ? AppTheme.errorColor.withOpacity(0.2)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUrgent 
                              ? AppTheme.errorColor 
                              : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isUrgent 
                                  ? AppTheme.errorColor 
                                  : AppTheme.primaryColor).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '$tableId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sipariş #$orderId',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUrgent 
                                  ? AppTheme.errorColor 
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('HH:mm').format(
                                    DateTime.parse(order['created_at'])),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: durationBgColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: durationColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            color: durationColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Sipariş içeriği alanı
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş İçeriği',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item['quantity']}x',
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item['name']}',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _markOrderAsReady(orderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text(
                      'Hazır Olarak İşaretle', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mutfak Paneli'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Siparişleri Yenile',
            onPressed: _fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showEditProfileDialog,
            borderRadius: BorderRadius.circular(40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'M',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve bilgiler
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Aktif Siparişler',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_orders.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Merhaba, $_userName',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Icon(
                              Icons.sync,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Sipariş listesi
                Expanded(
                  child: _orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Hazırlanacak sipariş bulunmuyor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Yeni siparişler beklemededir',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_orders[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 