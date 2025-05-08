import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchOrders();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final garsonRes =
      await http.get(Uri.parse('http://10.0.2.2:3000/users?role=garson'));
      final adminRes =
      await http.get(Uri.parse('http://10.0.2.2:3000/users?role=admin'));
      if (garsonRes.statusCode == 200 && adminRes.statusCode == 200) {
        setState(() {
          _garsons = json.decode(garsonRes.body);
          _admins = json.decode(adminRes.body);
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
    final currentUserEmail =
    null; // TODO: Giriş yapan adminin emailini buraya ekle (isteğe göre güncellenebilir)
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: Icon(Icons.person, color: Colors.deepOrange),
        ),
        title: Text(user['name'] ?? 'İsimsiz'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? ''),
            Row(
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(isAdmin ? 'Admin' : 'Garson',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAdmin)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.deepOrange),
                onPressed: () => _editGarson(
                    user['id'], user['name'] ?? '', user['email'] ?? ''),
              ),
            if (!isAdmin)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteUser(user['id']),
              ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yeni Kullanıcı Ekle',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: 'garson', child: Text('Garson')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _selectedRole = v ?? 'garson'),
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showAddUserModal = false),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addUser,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange),
                  child: _isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      floatingActionButton: _tabIndex != 2
          ? FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.person_add),
        onPressed: () => setState(() => _showAddUserModal = true),
      )
          : null,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.deepOrange,
                child: Row(
                  children: [
                    _buildTabButton('Garsonlar', 0, Icons.people),
                    _buildTabButton('Adminler', 1, Icons.admin_panel_settings),
                    _buildTabButton('Siparişler', 2, Icons.receipt_long),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _tabIndex == 0
                      ? _buildUserList(_garsons, 'garson')
                      : _tabIndex == 1
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange : Colors.deepOrange[200],
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users, String role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text('Kullanıcılar',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${users.length}',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: users.isEmpty
              ? const Center(child: Text('Henüz kullanıcı yok'))
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
}