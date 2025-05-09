import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../themes/app_theme.dart';
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
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Masalar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: _fetchActiveTables,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve bilgi alanı
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.table_bar,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Mevcut Masalar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: activeTableIds.isNotEmpty 
                                ? Colors.grey.shade600
                                : AppTheme.successColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                activeTableIds.isNotEmpty
                                    ? Icons.table_restaurant
                                    : Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activeTableIds.isEmpty
                                    ? 'Tüm Masalar Boş'
                                    : '${activeTableIds.length} Masa Dolu',
                                style: const TextStyle(
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
                    const SizedBox(height: 8),
                    Text(
                      'Sipariş açmak istediğiniz masaya tıklayın',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Masa listesi alanı
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: 20, // örnek olarak 20 masa
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (_, index) {
                      final tableNumber = index + 1;
                      final isActive = activeTableIds.contains(tableNumber);
                      
                      // Siparişi olan masalar 
                      if (isActive) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade400, width: 1.5),
                          ),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              0.3, 0.59, 0.11, 0, 0,
                              0.3, 0.59, 0.11, 0, 0,
                              0.3, 0.59, 0.11, 0, 0,
                              0,      0,      0,      1, 0,
                            ]),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
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
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Masa',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12, 
                                      vertical: 6
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock,
                                          color: Colors.black54,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Dolu',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
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
                      
                      // Boş masalar
                      return GestureDetector(
                        onTap: () => _createTableOrder(tableNumber),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
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
                                  child: Text(
                                    '$tableNumber',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Masa',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, 
                                    vertical: 6
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle,
                                        color: AppTheme.primaryColor,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sipariş Al',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
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
              ),
            ],
          ),
    );
  }
}
