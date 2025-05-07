import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'menuscreen.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({Key? key}) : super(key: key);

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<int> activeTableIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchActiveTables();
  }

  Future<void> _fetchActiveTables() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/orders'));
      if (response.statusCode == 200) {
        final orders = json.decode(response.body) as List;
        final ids = orders
            .where((order) => order['is_active'] == true)
            .map<int>((order) => order['table_id'] as int)
            .toSet()
            .toList();
        setState(() {
          activeTableIds = ids;
        });
      }
    } catch (_) {
      _showMessage('Sunucuya bağlanılamadı');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTableOrder(int tableId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'table_id': tableId}),
      );

      if (response.statusCode == 201) {
        _showMessage('Masa $tableId siparişe açıldı', success: true);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuScreen(tableId: tableId),
          ),
        );
      } else {
        _showMessage('Sipariş başlatılamadı');
      }
    } catch (_) {
      _showMessage('Sunucuya bağlanılamadı');
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masalar'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 20, // örnek olarak 20 masa
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (_, index) {
                final tableNumber = index + 1;
                final isActive = activeTableIds.contains(tableNumber);
                return GestureDetector(
                  onTap: () => _createTableOrder(tableNumber),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[200] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Masa $tableNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isActive ? Colors.green[900] : Colors.orange[900],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
