import 'dart:convert';

import 'package:http/http.dart' as http;

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String categoryId;
  final String? waiterId;
  final String? waiterName;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.categoryId,
    this.waiterId,
    this.waiterName,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'categoryId': categoryId,
      'waiterId': waiterId,
      'waiterName': waiterName,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 0,
      categoryId: map['categoryId']?.toString() ?? '',
      waiterId: map['waiterId']?.toString(),
      waiterName: map['waiterName']?.toString(),
    );
  }
}

class TableOrder {
  final int tableNumber;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final bool isActive;
  final bool isReady;

  TableOrder({
    required this.tableNumber,
    List<OrderItem>? items,
    this.createdAt,
    this.completedAt,
    this.isActive = true,
    this.isReady = false,
  }) : items = items ?? [];

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isActive': isActive,
      'isReady': isReady,
    };
  }

  factory TableOrder.fromMap(Map<String, dynamic> map) {
    try {
      final itemsList = (map['items'] as List?)
              ?.map((item) {
                if (item is Map<String, dynamic>) {
                  return OrderItem.fromMap(item);
                }
                return null;
              })
              .whereType<OrderItem>()
              .toList() ??
          [];

      return TableOrder(
        tableNumber: map['tableNumber'] as int? ?? 0,
        items: itemsList,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'])
            : null,
        completedAt: map['completedAt'] != null
            ? DateTime.tryParse(map['completedAt'])
            : null,
        isActive: map['isActive'] as bool? ?? false,
        isReady: map['isReady'] as bool? ?? false,
      );
    } catch (e) {
      print('Error parsing TableOrder: \$e');
      print('Map data: \$map');
      rethrow;
    }
  }
}

class OrderService {
  static Future<void> addItemToTable({
    required int tableId,
    required String name,
    required double price,
    required int quantity,
    required int categoryId,
    required int waiterId,
    required String waiterName,
  }) async {
    try {
      // API adresi - emülatör için 10.0.2.2, fiziksel cihaz için yerel IP
      final apiHost = '10.0.2.2:3000'; // veya 10.31.1.18:3000 fiziksel cihaz için
      
      // 1. Önce mevcut aktif siparişleri kontrol et
      final orderResponse = await http.get(
        Uri.parse('http://$apiHost/orders'),
      );
      
      if (orderResponse.statusCode != 200) {
        throw Exception('Siparişler alınamadı');
      }
      
      final orders = json.decode(orderResponse.body) as List;
      final activeOrders = orders
          .where((order) => 
              order['is_active'] == 1 && 
              order['table_id'] == tableId)
          .toList();
      
      int orderId;
      
      // Eğer zaten aktif sipariş varsa, onu kullan
      if (activeOrders.isNotEmpty) {
        orderId = activeOrders.first['id'];
        print('Mevcut sipariş bulundu: $orderId');
      } else {
        // Yoksa yeni sipariş oluştur
        final createOrderResponse = await http.post(
          Uri.parse('http://$apiHost/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'table_id': tableId}),
        );

        if (createOrderResponse.statusCode != 201) {
          throw Exception('Sipariş oluşturulamadı');
        }

        orderId = json.decode(createOrderResponse.body)['order_id'];
        print('Yeni sipariş oluşturuldu: $orderId');
      }

      // 2. Siparişe ürün ekle
      final addItemResponse = await http.put(
        Uri.parse('http://$apiHost/orders/$orderId/items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'price': price,
          'quantity': quantity,
          'category_id': categoryId,
          'waiter_id': waiterId,
          'waiter_name': waiterName,
        }),
      );

      if (addItemResponse.statusCode != 201) {
        throw Exception('Ürün siparişe eklenemedi');
      }
    } catch (e) {
      print('OrderService error: $e');
      rethrow;
    }
  }
}
