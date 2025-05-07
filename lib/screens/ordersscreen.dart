import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = false;

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
        setState(() {
          _orders = json.decode(response.body);
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
        _showMessage('Sipariş güncellendi', success: true);
        _fetchOrders();
      } else {
        _showMessage('Güncelleme başarısız');
      }
    } catch (e) {
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final total = items.fold<double>(0,
        (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masa: ${order['table_id']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
                'Garson: ${items.isNotEmpty ? items[0]['waiter_name'] ?? 'Bilinmiyor' : 'Bilinmiyor'}'),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(order['id'], 'ready'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Hazırla'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(order['id'], 'complete'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Tamamla'),
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
        title: const Text('Siparişler'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return _buildOrderCard(order);
                },
              ),
            ),
    );
  }
}
