import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ordersCollection = 'orders';
  final int totalTables = 15;

  // İlk kurulum - tüm masa dökümanlarını oluştur
  Future<void> initializeTables() async {
    final batch = _firestore.batch();
    
    for (int i = 1; i <= totalTables; i++) {
      final tableRef = _firestore.collection(_ordersCollection).doc(i.toString());
      final tableDoc = await tableRef.get();
      
      if (!tableDoc.exists) {
        batch.set(tableRef, {
          'items': [],
          'isActive': false,
          'isReady': false,
          'createdAt': null,
          'completedAt': null,
        });
      }
    }
    
    await batch.commit();
  }

  // Masa siparişini getir
  Stream<TableOrder?> getTableOrderStream(int tableNumber) {
    return _firestore
        .collection(_ordersCollection)
        .doc(tableNumber.toString())
        .snapshots()
        .map((doc) {
      try {
        if (doc.exists && doc.data()?['isActive'] == true) {
          final data = doc.data()!;
          return TableOrder.fromMap({
            ...data,
            'tableNumber': tableNumber,
          });
        }
        return null;
      } catch (e) {
        print('Error in getTableOrderStream: $e');
        print('Document data: ${doc.data()}');
        return null;
      }
    });
  }

  // Tüm aktif siparişleri getir
  Stream<List<TableOrder>> getAllActiveOrdersStream() {
    return _firestore
        .collection(_ordersCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return TableOrder.fromMap({
            ...data,
            'tableNumber': int.parse(doc.id),
          });
        }).toList();
      } catch (e) {
        print('Error in getAllActiveOrdersStream: $e');
        print('Snapshot data: ${snapshot.docs.map((doc) => doc.data())}');
        return [];
      }
    });
  }

  // Yeni sipariş oluştur
  Future<void> createTableOrder(int tableNumber) async {
    final orderRef = _firestore.collection(_ordersCollection).doc(tableNumber.toString());
    
    await orderRef.set({
      'items': [],
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'isActive': true,
      'isReady': false,
    });
  }

  // Masaya ürün ekle
  Future<void> addItemToTable(int tableNumber, OrderItem item) async {
    final orderRef = _firestore.collection(_ordersCollection).doc(tableNumber.toString());
    
    final orderDoc = await orderRef.get();
    if (!orderDoc.exists || !orderDoc.data()?['isActive']) {
      await createTableOrder(tableNumber);
    }

    final currentItems = orderDoc.exists 
        ? List<Map<String, dynamic>>.from(orderDoc.data()?['items'] ?? [])
        : [];
    
    final existingItemIndex = currentItems.indexWhere((i) => i['id'] == item.id);
    if (existingItemIndex != -1) {
      currentItems[existingItemIndex]['quantity'] += item.quantity;
    } else {
      currentItems.add(item.toMap());
    }

    await orderRef.update({
      'items': currentItems,
      'isActive': true,
      'isReady': false,
    });
  }

  // Masadan ürün sil
  Future<void> removeItemFromTable(int tableNumber, String itemId) async {
    final orderRef = _firestore.collection(_ordersCollection).doc(tableNumber.toString());
    
    final orderDoc = await orderRef.get();
    if (!orderDoc.exists) return;

    final currentItems = List<Map<String, dynamic>>.from(orderDoc.data()?['items'] ?? []);
    currentItems.removeWhere((item) => item['id'] == itemId);

    if (currentItems.isEmpty) {
      await closeTableOrder(tableNumber);
    } else {
      await orderRef.update({
        'items': currentItems,
      });
    }
  }

  // Üründen adet güncelle
  Future<void> updateItemQuantity(int tableNumber, String itemId, int newQuantity) async {
    final orderRef = _firestore.collection(_ordersCollection).doc(tableNumber.toString());
    
    final orderDoc = await orderRef.get();
    if (!orderDoc.exists) return;

    final currentItems = List<Map<String, dynamic>>.from(orderDoc.data()?['items'] ?? []);
    final itemIndex = currentItems.indexWhere((item) => item['id'] == itemId);

    if (itemIndex != -1) {
      if (newQuantity <= 0) {
        currentItems.removeAt(itemIndex);
        if (currentItems.isEmpty) {
          await closeTableOrder(tableNumber);
          return;
        }
      } else {
        currentItems[itemIndex]['quantity'] = newQuantity;
      }

      await orderRef.update({
        'items': currentItems,
      });
    }
  }

  // Siparişi tamamla
  Future<void> closeTableOrder(int tableNumber) async {
    final orderRef = _firestore.collection(_ordersCollection).doc(tableNumber.toString());
    
    await orderRef.set({
      'items': [],
      'isActive': false,
      'isReady': false,
      'completedAt': FieldValue.serverTimestamp(),
      'createdAt': null,
    });
  }
} 