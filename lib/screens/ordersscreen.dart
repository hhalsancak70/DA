import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../themes/app_theme.dart';
import 'menuscreen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  bool _isLoading = false;
  // Masa numarasına göre siparişleri gruplandırmak için Map
  Map<int, List<dynamic>> _ordersByTable = {};
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
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
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 10),
            Text(
              'Masa $tableId Kapat', 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Bu masadaki tüm siparişleri kapatmak istediğinize emin misiniz?', 
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _closeTable(tableId, orders);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Masayı Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
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
    
    // Hazır sipariş var mı kontrol et
    final bool hasReadyOrder = orders.any((order) => order['is_ready'] == true || order['is_ready'] == 1);
    
    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppTheme.cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ExpansionTile(
            collapsedBackgroundColor: hasReadyOrder 
                ? AppTheme.successColor.withOpacity(0.1) 
                : Colors.white,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
            shape: Border(),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasReadyOrder ? AppTheme.successColor : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (hasReadyOrder ? AppTheme.successColor : AppTheme.primaryColor).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
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
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long, 
                          size: 14, 
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${orders.length} Sipariş',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money, 
                          size: 14, 
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${totalOrdersAmount.toStringAsFixed(2)} ₺',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sipariş düzenleme butonu
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                  onPressed: () => _editTableOrder(tableId),
                  tooltip: 'Sipariş Düzenle',
                ),
                // Masa kapatma butonu
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.errorColor,
                    size: 22,
                  ),
                  onPressed: () => _showCloseTableConfirmation(tableId, orders),
                  tooltip: 'Masayı Kapat',
                ),
              ],
            ),
            children: [
              // İçerik
              Container(
                color: Colors.white,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final items = order['items'] as List<dynamic>? ?? [];
                    final total = items.fold<double>(0, (sum, item) => 
                        sum + ((double.tryParse(item['price'].toString()) ?? 0) * (item['quantity'] ?? 1)));
                    final isReady = order['is_ready'] == true || order['is_ready'] == 1;
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: isReady 
                          ? AppTheme.successColor.withOpacity(0.05) 
                          : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sipariş başlığı
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt,
                                    color: AppTheme.primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sipariş #${order['id']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (isReady)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'HAZIR',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Sipariş içeriği
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                ...items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'x${item['quantity']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item['name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${item['price']} ₺',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Toplam',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${total.toStringAsFixed(2)} ₺',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // İşlem butonları
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Kapat butonu kaldırıldı
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.receipt_long, size: 22),
            const SizedBox(width: 8),
            const Text('Siparişler'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : Column(
              children: [
                // Başlık ve bilgilendirme alanı
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                          Icon(
                            Icons.table_bar,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aktif Masalar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sipariş alan masaların listesi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_ordersByTable.length} Masa',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Masa siparişleri alanı
                Expanded(
                  child: _ordersByTable.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_bar,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aktif masa bulunmuyor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Henüz sipariş verilmemiş',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          color: AppTheme.primaryColor,
                          child: ListView(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            children: _ordersByTable.entries
                                .map((entry) => _buildTableOrdersSection(entry.key, entry.value))
                                .toList(),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
