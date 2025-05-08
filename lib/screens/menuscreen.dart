import 'dart:convert';

import 'package:digiadi/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MenuScreen extends StatefulWidget {
  final int tableId;
  const MenuScreen({Key? key, required this.tableId}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, List<dynamic>> _menu = {};
  String waiterName = '';
  int waiterId = 0;
  Map<String, dynamic>? _currentOrder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadWaiterInfo();
    _fetchCurrentOrder();
  }

  Future<void> _fetchCurrentOrder() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/orders'));
      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);
        final currentOrder = orders.firstWhere(
          (order) => order['table_id'] == widget.tableId && order['is_active'] == 1,
          orElse: () => null,
        );
        
        setState(() {
          _currentOrder = currentOrder;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Sipariş yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMenu() async {
    final String jsonString =
        await rootBundle.loadString('assets/json/yemekler.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    // JSON yapısında kategorilere ürünleri eşleyelim
    Map<String, List<dynamic>> menuByCategory = {};
    
    final List<dynamic> products = jsonData['urunler'] ?? [];
    final List<dynamic> categories = jsonData['kategoriler'] ?? [];
    
    // Kategori isimlerini ID'lere eşlemek için map oluştur
    Map<int, String> categoryNameById = {};
    for (var category in categories) {
      categoryNameById[category['id']] = category['isim'];
    }
    
    // Ürünleri kategorilere göre ayır
    for (var product in products) {
      final categoryId = product['kategori'];
      final categoryName = categoryNameById[categoryId] ?? 'Diğer';
      
      if (!menuByCategory.containsKey(categoryName)) {
        menuByCategory[categoryName] = [];
      }
      
      menuByCategory[categoryName]!.add(product);
    }
    
    setState(() {
      _menu = menuByCategory;
    });
  }

  Future<void> _loadWaiterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      waiterName = prefs.getString('waiterName') ?? 'Garson';
      waiterId = prefs.getInt('waiterId') ?? 1;
    });
  }

  void _showItemsModal(String category, List items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView.builder(
              controller: controller,
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  child: ListTile(
                    leading: item['resim'] != null 
                        ? Image.asset(item['resim'],
                            width: 50, height: 50, fit: BoxFit.cover)
                        : Container(width: 50, height: 50, color: Colors.grey),
                    title: Text(item['isim'] ?? ''),
                    subtitle: Text('${item['fiyat'] ?? 0} ₺'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await OrderService.addItemToTable(
                          tableId: widget.tableId,
                          name: item['isim'] ?? '',
                          price: double.parse((item['fiyat'] ?? 0).toString()),
                          quantity: 1,
                          categoryId: item['kategori'] ?? 0,
                          waiterId: waiterId,
                          waiterName: waiterName,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item['isim'] ?? ''} eklendi')),
                        );
                        // Siparişi yenile
                        _fetchCurrentOrder();
                      },
                      child: const Text('Ekle'),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentOrderCard() {
    if (_currentOrder == null) {
      return const SizedBox.shrink();
    }

    final items = _currentOrder!['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = items.fold<double>(0,
          (sum, item) => sum + ((double.tryParse(item['price'].toString()) ?? 0) * (item['quantity'] ?? 1)));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mevcut Sipariş', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              Text('Toplam: ${total.toStringAsFixed(2)} ₺',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item['name']),
                subtitle: Text('${item['price']} ₺'),
                trailing: Text('x${item['quantity']}'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menü - Masa ${widget.tableId}'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCurrentOrderCard(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _menu.keys.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (_, index) {
                      final category = _menu.keys.elementAt(index);
                      final items = _menu[category] ?? [];
                      return GestureDetector(
                        onTap: () => _showItemsModal(category, items),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA726), Color(0xFFEF5350)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
