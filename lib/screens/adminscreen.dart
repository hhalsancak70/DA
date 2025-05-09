import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../themes/app_theme.dart';
import 'loginscreen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  List<dynamic> _garsons = [];
  List<dynamic> _admins = [];
  List<dynamic> _kitchens = [];
  List<dynamic> _orders = [];
  bool _isLoading = false;
  bool _isOrderLoading = false;
  bool _showAddUserModal = false;
  String _selectedRole = 'garson';
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int? _editingGarsonId;
  final _editNameController = TextEditingController();
  final _editEmailController = TextEditingController();
  final _editPasswordController = TextEditingController();
  
  // Kullanıcı bilgileri
  String _adminName = 'Admin';
  String _adminEmail = '';
  String _userId = '';
  
  // Profil düzenleme için controller'lar
  final _profileNameController = TextEditingController();
  final _profileEmailController = TextEditingController();
  final _profilePasswordController = TextEditingController();
  final _profileConfirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isProfileLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUsers();
    _fetchOrders();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('userName') ?? 'Admin';
      _adminEmail = prefs.getString('userEmail') ?? '';
      _userId = prefs.getString('userId') ?? '';
      
      // Controller'ları güncelle
      _profileNameController.text = _adminName;
      _profileEmailController.text = _adminEmail;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _editNameController.dispose();
    _editEmailController.dispose();
    _editPasswordController.dispose();
    _profileNameController.dispose();
    _profileEmailController.dispose();
    _profilePasswordController.dispose();
    _profileConfirmPasswordController.dispose();
    super.dispose();
  }
  
  // Kullanıcı bilgilerini güncelleme
  Future<void> _updateUserProfile() async {
    if (_profileNameController.text.trim().isEmpty || _profileEmailController.text.trim().isEmpty) {
      _showMessage('Lütfen isim ve e-posta alanlarını doldurun');
      return;
    }
    
    // Yeni şifre girilmişse kontrol et
    if (_profilePasswordController.text.isNotEmpty) {
      if (_profilePasswordController.text != _profileConfirmPasswordController.text) {
        _showMessage('Şifreler eşleşmiyor');
        return;
      }
      if (_profilePasswordController.text.length < 6) {
        _showMessage('Şifre en az 6 karakter olmalıdır');
        return;
      }
    }
    
    setState(() => _isProfileLoading = true);
    
    // Güncelleme verisini hazırla
    final Map<String, dynamic> updateData = {
      'name': _profileNameController.text.trim(),
      'email': _profileEmailController.text.trim(),
    };
    
    // Eğer şifre girilmişse ekle
    if (_profilePasswordController.text.isNotEmpty) {
      updateData['password'] = _profilePasswordController.text;
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
        prefs.setString('userName', _profileNameController.text.trim());
        prefs.setString('userEmail', _profileEmailController.text.trim());
        
        setState(() {
          _adminName = _profileNameController.text.trim();
          _adminEmail = _profileEmailController.text.trim();
        });
        
        _showMessage('Profil bilgileriniz güncellendi', success: true);
        Navigator.of(context).pop(); // Diyaloğu kapat
        
        // Şifreleri temizle
        _profilePasswordController.clear();
        _profileConfirmPasswordController.clear();
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
                    controller: _profileNameController,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'İsim',
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // E-posta alanı
                  TextField(
                    controller: _profileEmailController,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  
                  // Şifre alanı (isteğe bağlı)
                  TextField(
                    controller: _profilePasswordController,
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
                    controller: _profileConfirmPasswordController,
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

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final garsonRes =
      await http.get(Uri.parse('http://10.0.2.2:3000/users?role=garson'));
      final adminRes =
      await http.get(Uri.parse('http://10.0.2.2:3000/users?role=admin'));
      final kitchenRes =
      await http.get(Uri.parse('http://10.0.2.2:3000/users?role=mutfak'));
      
      if (garsonRes.statusCode == 200 && adminRes.statusCode == 200 && kitchenRes.statusCode == 200) {
        setState(() {
          _garsons = json.decode(garsonRes.body);
          _admins = json.decode(adminRes.body);
          _kitchens = json.decode(kitchenRes.body);
        });
      } else {
        _showMessage('Kullanıcılar yüklenemedi');
      }
    } catch (e) {
      _showMessage('Sunucuya bağlanılamadı');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => _isOrderLoading = true);
    try {
      final response =
      await http.get(Uri.parse('http://10.0.2.2:3000/orders'));
      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> allOrders = json.decode(response.body);
          _orders = allOrders.where((order) => order['is_active'] == true || order['is_active'] == 1).toList();
        });
      } else {
        _showMessage('Siparişler yüklenemedi');
      }
    } catch (e) {
      _showMessage('Sunucuya bağlanılamadı');
    } finally {
      setState(() => _isOrderLoading = false);
    }
  }

  Future<void> _addUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': _selectedRole,
        }),
      );
      if (response.statusCode == 201) {
        _showMessage('Kullanıcı eklendi', success: true);
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() => _showAddUserModal = false);
        _fetchUsers();
      } else {
        final data = json.decode(response.body);
        _showMessage(data['error'] ?? 'Kayıt başarısız');
      }
    } catch (_) {
      _showMessage('Sunucuya bağlanılamadı');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final response =
      await http.delete(Uri.parse('http://10.0.2.2:3000/users/$userId'));
      if (response.statusCode == 200) {
        _showMessage('Kullanıcı silindi', success: true);
        _fetchUsers();
      } else {
        _showMessage('Silme işlemi başarısız');
      }
    } catch (_) {
      _showMessage('Sunucuya bağlanılamadı');
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    final endpoint = status == 'ready'
        ? 'ready'
        : status == 'complete'
        ? 'complete'
        : '';
    if (endpoint.isEmpty) return;
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/orders/$orderId/$endpoint'),
      );
      if (response.statusCode == 200) {
        _showMessage('Sipariş güncellendi', success: true);
        _fetchOrders();
      } else {
        _showMessage('Güncelleme başarısız');
      }
    } catch (e) {
      _showMessage('Sunucuya bağlanılamadı');
    }
  }

  Future<void> _closeTable(int tableId) async {
    try {
      final tableOrders = _orders.where((order) => order['table_id'] == tableId).toList();
      for (var order in tableOrders) {
        final orderId = order['id'];
        await http.put(
          Uri.parse('http://10.0.2.2:3000/orders/$orderId/complete'),
        );
      }
      _showMessage('Masa $tableId kapatıldı', success: true);
      _fetchOrders();
    } catch (e) {
      _showMessage('Masa kapatılırken hata oluştu');
    }
  }

  void _showCloseTableConfirmation(int tableId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Masa $tableId Kapat', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bu masadaki tüm siparişleri kapatmak istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _closeTable(tableId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Masayı Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _editGarson(int userId, String name, String email) async {
    _editingGarsonId = userId;
    _editNameController.text = name;
    _editEmailController.text = email;
    _editPasswordController.text = '';
    setState(() {});
  }

  Future<void> _updateGarson() async {
    final name = _editNameController.text.trim();
    final email = _editEmailController.text.trim();
    final password = _editPasswordController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final body = {
        'name': name,
        'email': email,
      };
      if (password.isNotEmpty) body['password'] = password;
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/users/$_editingGarsonId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        _showMessage('Garson güncellendi', success: true);
        _editingGarsonId = null;
        _editNameController.clear();
        _editEmailController.clear();
        _editPasswordController.clear();
        _fetchUsers();
      } else {
        final data = json.decode(response.body);
        _showMessage(data['error'] ?? 'Güncelleme başarısız');
      }
    } catch (_) {
      _showMessage('Sunucuya bağlanılamadı');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String role) {
    final isAdmin = role == 'admin';
    final currentUserEmail = null;
    
    // Rol adını belirle
    String roleName = 'Kullanıcı';
    if (role == 'admin') roleName = 'Admin';
    else if (role == 'garson') roleName = 'Garson';
    else if (role == 'mutfak') roleName = 'Mutfak';

    Color roleColor = AppTheme.primaryColor;
    if (role == 'admin') roleColor = Colors.purple;
    else if (role == 'garson') roleColor = AppTheme.primaryColor;
    else if (role == 'mutfak') roleColor = Colors.green;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.1),
          child: Icon(
            role == 'admin' 
                ? Icons.admin_panel_settings
                : role == 'mutfak' 
                    ? Icons.restaurant
                    : Icons.person,
            color: roleColor,
          ),
        ),
        title: Text(
          user['name'] ?? 'İsimsiz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user['email'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    role == 'admin' 
                        ? Icons.verified_user
                        : role == 'mutfak' 
                            ? Icons.restaurant_menu
                            : Icons.badge,
                    size: 14,
                    color: roleColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    roleName, 
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: !isAdmin 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit, 
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    onPressed: () => _editGarson(
                        user['id'], user['name'] ?? '', user['email'] ?? ''),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete, 
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    onPressed: () => _deleteUser(user['id']),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final total = items.fold<double>(0,
            (sum, item) => sum + ((double.tryParse(item['price'].toString()) ?? 0) * (item['quantity'] ?? 1)));
    final isReady = order['is_ready'] == true || order['is_ready'] == 1;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isReady ? Colors.orange.shade50 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isReady ? Colors.orange.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${order['table_id']}',
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
                          'Sipariş #${order['id']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order['created_at'] != null
                              ? order['created_at'].toString().substring(0, 16)
                              : '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isReady)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'HAZIR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item['name']} x${item['quantity']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${item['price']} ₺',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${total.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isReady)
              ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(order['id'], 'ready'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                icon: const Icon(Icons.restaurant, size: 18),
                label: const Text('Hazır Olarak İşaretle'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddUserModal() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Yeni Kullanıcı Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: [
                DropdownMenuItem(
                  value: 'garson', 
                  child: Row(
                    children: [
                      Icon(
                        Icons.person, 
                        color: AppTheme.primaryColor, 
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Garson'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'mutfak', 
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant, 
                        color: Colors.green, 
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Mutfak'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'admin', 
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings, 
                        color: Colors.purple, 
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Admin'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedRole = v ?? 'garson'),
              decoration: AppTheme.inputDecoration(
                labelText: 'Rol',
                prefixIcon: Icons.badge,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: AppTheme.inputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: AppTheme.inputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icons.mail_outline,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: AppTheme.inputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icons.lock_outline,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showAddUserModal = false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addUser,
                  style: AppTheme.elevatedButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, 
                            color: Colors.white,
                          ),
                        )
                      : const Text('Ekle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditGarsonModal() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Garson Bilgilerini Düzenle',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange)),
            const SizedBox(height: 16),
            TextField(
              controller: _editNameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _editEmailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _editPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (değiştirmek için)',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _editingGarsonId = null;
                    _editNameController.clear();
                    _editEmailController.clear();
                    _editPasswordController.clear();
                    setState(() {});
                  },
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateGarson,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange),
                  child: _isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Text('Kaydet'),
                ),
              ],
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
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
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
                  _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
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
      floatingActionButton: _tabIndex != 3
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.person_add),
              onPressed: () => setState(() => _showAddUserModal = true),
            )
          : null,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: AppTheme.primaryColor,
                child: Row(
                  children: [
                    _buildTabButton('Garsonlar', 0, Icons.people),
                    _buildTabButton('Mutfak', 1, Icons.restaurant),
                    _buildTabButton('Adminler', 2, Icons.admin_panel_settings),
                    _buildTabButton('Siparişler', 3, Icons.receipt_long),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _tabIndex == 0
                      ? _buildUserList(_garsons, 'garson')
                      : _tabIndex == 1
                          ? _buildUserList(_kitchens, 'mutfak')
                          : _tabIndex == 2
                              ? _buildUserList(_admins, 'admin')
                              : _buildOrderList(),
                ),
              ),
            ],
          ),
          if (_showAddUserModal) _buildAddUserModal(),
          if (_editingGarsonId != null) _buildEditGarsonModal(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label, 
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users, String role) {
    String roleTitle = 'Kullanıcılar';
    IconData roleIcon = Icons.people;
    Color roleColor = AppTheme.primaryColor;
    
    if (role == 'admin') {
      roleTitle = 'Adminler';
      roleIcon = Icons.admin_panel_settings;
      roleColor = Colors.purple;
    } else if (role == 'garson') {
      roleTitle = 'Garsonlar';
      roleIcon = Icons.people;
      roleColor = AppTheme.primaryColor;
    } else if (role == 'mutfak') {
      roleTitle = 'Mutfak Ekibi';
      roleIcon = Icons.restaurant;
      roleColor = Colors.green;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(roleIcon, color: roleColor, size: 24),
            const SizedBox(width: 12),
            Text(
              roleTitle,
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${users.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        roleIcon,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz $roleTitle yok',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sağ alttaki + butonuna tıklayarak ekleyebilirsiniz',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) =>
                      _buildUserCard(users[index], role),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderList() {
    if (_isOrderLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }
    
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aktif sipariş bulunmuyor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    final Map<int, List<dynamic>> ordersByTable = {};
    for (var order in _orders) {
      final tableId = order['table_id'] as int;
      if (!ordersByTable.containsKey(tableId)) {
        ordersByTable[tableId] = [];
      }
      ordersByTable[tableId]!.add(order);
    }
    
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.restaurant,
                color: Colors.deepOrange,
              ),
              const SizedBox(width: 8),
              Text(
                '${ordersByTable.length} Aktif Masa',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
        ...ordersByTable.entries.map((entry) {
          final tableId = entry.key;
          final tableOrders = entry.value;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Masa $tableId',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCloseTableConfirmation(tableId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Masayı Kapat'),
                    ),
                  ],
                ),
              ),
              ...tableOrders.map((order) => _buildOrderCard(order)).toList(),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _showFeatureUnderDevelopment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu özellik henüz geliştirme aşamasındadır.'),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        margin: EdgeInsets.all(10),
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