import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'menuscreen.dart';
import 'ordersscreen.dart';

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
            .where((order) => order['is_active'] == true || order['is_active'] == 1)
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
        await _fetchActiveTables();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuScreen(tableId: tableId),
          ),
        ).then((_) => _fetchActiveTables());
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Masalar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: _fetchActiveTables,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepOrange.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepOrange,
                  strokeWidth: 3,
                ),
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 12),
                        child: Text(
                          'Mevcut Masalar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(4),
                          itemCount: 20, // örnek olarak 20 masa
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (_, index) {
                            final tableNumber = index + 1;
                            final isActive = activeTableIds.contains(tableNumber);
                            
                            // Siparişi olan masalar için kesinlikle tıklanamaz bir container oluştur
                            if (isActive) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.grey[600]!, width: 1.5),
                                ),
                                child: ColorFiltered(
                                  // Siyah-beyaz görünümü için ColorFilter uygula
                                  colorFilter: const ColorFilter.matrix(<double>[
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0,      0,      0,      1, 0,
                                  ]),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$tableNumber',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Masa',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6, 
                                            vertical: 2
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade500.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                'Dolu',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            // Boş masalar için GestureDetector ile sarılmış container
                            return GestureDetector(
                              onTap: () => _createTableOrder(tableNumber),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.orange[300]!, width: 1.5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade400,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$tableNumber',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Masa',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6, 
                                          vertical: 2
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_circle,
                                              color: Colors.deepOrange,
                                              size: 12,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'Sipariş Al',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
