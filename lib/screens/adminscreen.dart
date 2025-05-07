import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<dynamic> _users = [];
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:3000/users?role=garson'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _users = decoded;
        });
      } else {
        _showMessage('Kullanıcılar yüklenemedi');
      }
    } catch (e) {
      _showMessage('Sunucuya bağlanılamadı');
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
          'role': 'garson',
        }),
      );

      if (response.statusCode == 201) {
        _showMessage('Garson eklendi', success: true);
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
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

  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yeni Garson Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _addUser,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ekle'),
              ),
              const SizedBox(height: 24),
              const Text('Kayıtlı Garsonlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _users.isEmpty
                  ? const Center(child: Text('Henüz kullanıcı yok'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          child: ListTile(
                            title: Text(user['name'] ?? 'İsimsiz'),
                            subtitle: Text(user['email']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user['id']),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
