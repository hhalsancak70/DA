import 'dart:convert';

import 'package:digiadi/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadWaiterInfo();
  }

  Future<void> _loadMenu() async {
    final String jsonString =
        await rootBundle.loadString('assets/json/yemekler.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    setState(() {
      _menu = jsonData.map((key, value) => MapEntry(key, List.from(value)));
    });
  }

  Future<void> _loadWaiterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      waiterName = prefs.getString('waiterName') ?? 'Garson';
      waiterId = prefs.getInt('waiterId') ?? 0;
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
                    leading: Image.asset(item['image'],
                        width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(item['name']),
                    subtitle: Text('${item['price']} ₺'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await OrderService.addItemToTable(
                          tableId: widget.tableId,
                          name: item['name'],
                          price: double.parse(item['price'].toString()),
                          quantity: 1,
                          categoryId:
                              int.tryParse(item['category_id'].toString()) ?? 0,
                          waiterId: waiterId,
                          waiterName: waiterName,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item['name']} eklendi')),
                        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menü'),
        backgroundColor: Colors.deepOrange,
      ),
      body: GridView.builder(
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
    );
  }
}
