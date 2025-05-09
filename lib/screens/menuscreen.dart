import 'dart:convert';

import 'package:digiadi/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../themes/app_theme.dart';

class MenuScreen extends StatefulWidget {
  final int tableId;
  const MenuScreen({Key? key, required this.tableId}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  Map<String, List<dynamic>> _menu = {};
  String waiterName = '';
  int waiterId = 0;
  Map<String, dynamic>? _currentOrder;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadWaiterInfo();
    _fetchCurrentOrder();
    
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
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, controller) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Başlık ve çekme çubuğu
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Çekme çubuğu
                          Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    color: AppTheme.primaryColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              // Kapatma butonu
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close,
                                  color: AppTheme.textSecondary,
                                  size: 24,
                                ),
                                tooltip: 'Kapat',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Ürün listesi
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          // Adet sayısını tutmak için bir değişken
                          int quantity = 1;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.shadowColor,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: StatefulBuilder(
                              builder: (BuildContext context, StateSetter setItemState) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: item['resim'] != null 
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.asset(
                                              item['resim'],
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Icon(
                                            Icons.fastfood,
                                            color: AppTheme.primaryColor,
                                            size: 30,
                                          ),
                                  ),
                                  title: Text(
                                    item['isim'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Fiyat: ${item['fiyat'] ?? 0} ₺',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Adet kontrol alanı
                                      Row(
                                        children: [
                                          Text(
                                            'Adet: ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.primaryColor.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Azaltma butonu
                                                InkWell(
                                                  onTap: () {
                                                    if (quantity > 1) {
                                                      setItemState(() {
                                                        quantity--;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.remove,
                                                      size: 18,
                                                      color: quantity > 1 
                                                          ? AppTheme.primaryColor 
                                                          : Colors.grey.shade400,
                                                    ),
                                                  ),
                                                ),
                                                // Adet
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                                    border: Border(
                                                      left: BorderSide(
                                                        color: AppTheme.primaryColor.withOpacity(0.2), 
                                                        width: 1
                                                      ),
                                                      right: BorderSide(
                                                        color: AppTheme.primaryColor.withOpacity(0.2), 
                                                        width: 1
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    quantity.toString(),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold, 
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                                // Arttırma butonu
                                                InkWell(
                                                  onTap: () {
                                                    setItemState(() {
                                                      quantity++;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 18,
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: ElevatedButton.icon(
                                    onPressed: () async {
                                      await OrderService.addItemToTable(
                                        tableId: widget.tableId,
                                        name: item['isim'] ?? '',
                                        price: double.parse((item['fiyat'] ?? 0).toString()),
                                        quantity: quantity,
                                        categoryId: item['kategori'] ?? 0,
                                        waiterId: waiterId,
                                        waiterName: waiterName,
                                      );
                                      if (!mounted) return;
                                      
                                      // Modal kapatılmıyor
                                      _showMessage('${item['isim'] ?? ''} eklendi (${quantity} adet)', success: true);
                                      // Adet miktarını sıfırla
                                      setItemState(() {
                                        quantity = 1;
                                      });
                                      // Siparişi yenile
                                      _fetchCurrentOrder();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Ekle'),
                                  ),
                                );
                              }
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
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
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık alanı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mevcut Sipariş', 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${total.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Ürünler listesi
          Padding(
            padding: const EdgeInsets.all(16),
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
                            padding: const EdgeInsets.all(6),
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
                          const SizedBox(width: 12),
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
              ],
            ),
          ),
        ],
      ),
    );
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
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, size: 22),
            const SizedBox(width: 8),
            Text('Masa ${widget.tableId} - Menü'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading 
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : Column(
              children: [
                // Menü hakkında bilgi içeren banner
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
                    children: [
                      Icon(
                        Icons.restaurant,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategoriler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'İstediğiniz kategoriyi seçin',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                // Mevcut sipariş (varsa)
                if (_currentOrder != null) _buildCurrentOrderCard(),
                
                // Kategoriler grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _menu.keys.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (_, index) {
                      final category = _menu.keys.elementAt(index);
                      final items = _menu[category] ?? [];
                      
                      // Kategoriye özel renkler için basit bir algoritma
                      final hue = (index * 25) % 360;
                      final color = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.7, 0.5).toColor();
                      
                      return FadeTransition(
                        opacity: _animation,
                        child: GestureDetector(
                          onTap: () => _showItemsModal(category, items),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  color,
                                  color.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Kategori içerik
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Kategori ikonu
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.restaurant,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Kategori adı
                                      Text(
                                        category,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Ürün sayısı
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${items.length} ürün',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
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
    );
  }
}
