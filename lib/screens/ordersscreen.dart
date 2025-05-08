import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'menuscreen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = false;
  // Masa numarasına göre siparişleri gruplandırmak için Map
  Map<int, List<dynamic>> _ordersByTable = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/orders'));
      if (response.statusCode == 200) {
        final List<dynamic> allOrders = json.decode(response.body);
        // Sadece aktif siparişleri filtrele
        final activeOrders = allOrders.where((order) => order['is_active'] == 1).toList();
        
        // Siparişleri masa numarasına göre grupla
        final Map<int, List<dynamic>> tableOrders = {};
        for (var order in activeOrders) {
          final tableId = order['table_id'] as int;
          if (!tableOrders.containsKey(tableId)) {
            tableOrders[tableId] = [];
          }
          tableOrders[tableId]!.add(order);
        }
        
        setState(() {
          _orders = activeOrders;
          _ordersByTable = tableOrders;
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
        if (status == 'ready') {
          _showMessage('Sipariş hazırlandı', success: true);
        } else if (status == 'complete') {
          _showMessage('Masa kapatıldı', success: true);
        }
        
        // Eğer sipariş tamamlandıysa, siparişi listeden kaldır
        if (status == 'complete') {
          setState(() {
            for (var tableId in _ordersByTable.keys) {
              _ordersByTable[tableId]?.removeWhere((order) => order['id'] == orderId);
              if (_ordersByTable[tableId]?.isEmpty ?? true) {
                _ordersByTable.remove(tableId);
              }
            }
            _orders.removeWhere((order) => order['id'] == orderId);
          });
        } else {
          _fetchOrders(); // Diğer durumlarda tüm listeyi yenile
        }
      } else {
        if (status == 'ready') {
          _showMessage('Sipariş hazırlanamadı');
        } else if (status == 'complete') {
          _showMessage('Masa kapatılamadı');
        }
      }
    } catch (e) {
      _showMessage('Sunucuya bağlanılamadı');
    }
  }

  Future<void> _closeTable(int tableId, List<dynamic> orders) async {
    try {
      // Masadaki tüm siparişleri kapat
      for (var order in orders) {
        final orderId = order['id'];
        await http.put(
          Uri.parse('http://10.0.2.2:3000/orders/$orderId/complete'),
        );
      }
      
      // Başarılı mesajı göster
      _showMessage('Masa $tableId kapatıldı', success: true);
      
      // UI'ı güncelle
      setState(() {
        _ordersByTable.remove(tableId);
        _orders.removeWhere((order) => order['table_id'] == tableId);
      });
    } catch (e) {
      _showMessage('Masa kapatılırken hata oluştu: $e');
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

  void _editTableOrder(int tableId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuScreen(tableId: tableId),
      ),
    ).then((_) => _fetchOrders()); // Sayfadan geri dönünce siparişleri yenile
  }

  void _showCloseTableConfirmation(int tableId, List<dynamic> orders) {
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
              _closeTable(tableId, orders);
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

  Widget _buildTableOrdersSection(int tableId, List<dynamic> orders) {
    final totalOrdersAmount = orders.fold<double>(0, (sum, order) {
      final items = order['items'] as List<dynamic>? ?? [];
      return sum + items.fold<double>(0, 
        (itemSum, item) => itemSum + ((double.tryParse(item['price'].toString()) ?? 0) * (item['quantity'] ?? 1)));
    });
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.orange.shade50,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$tableId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Masa $tableId',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 2.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length} Sipariş',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Toplam: ${totalOrdersAmount.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          children: orders.map((order) => _buildOrderCard(order)).toList(),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editTableOrder(tableId),
                  tooltip: 'Siparişi Düzenle',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _showCloseTableConfirmation(tableId, orders),
                  tooltip: 'Masayı Kapat',
                ),
              ),
            ],
          ),
          initiallyExpanded: true,
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final total = items.fold<double>(0,
            (sum, item) => sum + ((double.tryParse(item['price'].toString()) ?? 0) * (item['quantity'] ?? 1)));
    final isReady = order['is_ready'] == 1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isReady ? Colors.green.shade50 : Colors.grey.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isReady ? Colors.green.shade200 : Colors.grey.shade200,
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
                    Icon(
                      Icons.receipt,
                      color: isReady ? Colors.green : Colors.grey.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sipariş #${order['id']}',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: isReady ? Colors.green.shade800 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (isReady)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
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
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Garson: ${items.isNotEmpty ? items[0]['waiter_name'] ?? 'Bilinmiyor' : 'Bilinmiyor'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['name']} x${item['quantity']}'),
                      Text('${item['price']} ₺'),
                    ],
                  ),
                )),
            const Divider(),
            Text('Toplam: ${total.toStringAsFixed(2)} ₺',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                // Eğer sipariş hazırsa, Hazırla butonunu devre dışı bırak
                ElevatedButton(
                  onPressed: isReady ? null : () => _updateOrderStatus(order['id'], 'ready'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text('Hazırla'),
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
      appBar: AppBar(
        title: const Text(
          'Aktif Masalar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 26),
            onPressed: _fetchOrders,
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
            : RefreshIndicator(
                onRefresh: _fetchOrders,
                color: Colors.deepOrange,
                child: _ordersByTable.isEmpty
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
                          const Text(
                            'Aktif masa bulunmuyor',
                            style: TextStyle(
                              fontSize: 18, 
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Yeni sipariş almak için masalara dönün',
                            style: TextStyle(
                              fontSize: 14, 
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Masalara Dön'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.table_bar, 
                                color: Colors.deepOrange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_ordersByTable.length} Aktif Masa',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._ordersByTable.entries
                            .map((entry) => _buildTableOrdersSection(entry.key, entry.value))
                            .toList(),
                      ],
                    ),
              ),
      ),
    );
  }
}
