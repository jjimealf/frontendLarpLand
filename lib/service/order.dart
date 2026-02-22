import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:larpland/model/order.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/service/firebase_backend.dart';

CollectionReference<Map<String, dynamic>> get _ordersCollection =>
    FirebaseBackend.firestore.collection('orders');

Future<int> createUserOrder({
  required int userId,
  required List<Product> cartItems,
  required double subtotalAmount,
  required double shippingAmount,
  required double totalAmount,
  String status = 'completed',
  String? paymentMethod,
  String? deliveryMethod,
  String? customerName,
  String? customerPhone,
  String? notes,
  Map<String, dynamic>? shippingAddress,
}) async {
  FirebaseBackend.ensureInitialized();
  if (cartItems.isEmpty) {
    throw Exception('No hay productos para registrar en el pedido.');
  }

  final orderId = await FirebaseBackend.nextNumericId('orders');
  final normalizedItems = cartItems
      .map((item) {
        final unitPrice = _parsePrice(item.precio);
        final quantity = item.cantidadCarrito;
        return <String, dynamic>{
          'product_id': item.id,
          'product_name': item.nombre,
          'unit_price': item.precio,
          'quantity': quantity,
          'line_total': unitPrice * quantity,
          'image_url': item.imagen,
        };
      })
      .toList(growable: false);

  final computedSubtotal = normalizedItems.fold<double>(
    0,
    (acc, item) => acc + ((item['line_total'] as num?)?.toDouble() ?? 0),
  );
  final totalItems = normalizedItems.fold<int>(
    0,
    (acc, item) => acc + ((item['quantity'] as num?)?.toInt() ?? 0),
  );

  await _ordersCollection.add(<String, dynamic>{
    'id': orderId,
    'user_id': userId,
    'status': status,
    'payment_method': paymentMethod ?? 'card',
    'delivery_method': deliveryMethod ?? 'standard',
    if (customerName != null) 'customer_name': customerName,
    if (customerPhone != null) 'customer_phone': customerPhone,
    if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    if (shippingAddress != null) 'shipping_address': shippingAddress,
    'subtotal_amount': subtotalAmount,
    'shipping_amount': shippingAmount,
    'total_amount': totalAmount,
    'computed_subtotal_amount': computedSubtotal,
    'total_items': totalItems,
    'items': normalizedItems,
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  });

  return orderId;
}

Future<List<UserOrder>> fetchUserOrders(int userId) async {
  FirebaseBackend.ensureInitialized();
  final snapshot = await FirebaseBackend.firestore
      .collection('orders')
      .where('user_id', isEqualTo: userId)
      .get();

  final orders = snapshot.docs
      .map(FirebaseBackend.normalizeSnapshotData)
      .map(UserOrder.fromJson)
      .toList(growable: false);

  final sorted = List<UserOrder>.from(orders);
  sorted.sort((a, b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
  return sorted;
}

Future<List<UserOrder>> fetchAllOrders() async {
  FirebaseBackend.ensureInitialized();
  final snapshot = await _ordersCollection.get();
  final orders = snapshot.docs
      .map(FirebaseBackend.normalizeSnapshotData)
      .map(UserOrder.fromJson)
      .toList(growable: false);

  final sorted = List<UserOrder>.from(orders);
  sorted.sort((a, b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
  return sorted;
}

Future<void> updateOrderStatus({
  required int orderId,
  required String status,
}) async {
  FirebaseBackend.ensureInitialized();
  final ref = await FirebaseBackend.findRefByNumericId(_ordersCollection, orderId);
  await ref.set(<String, dynamic>{
    'status': status.trim().toLowerCase(),
    'updated_at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

double _parsePrice(String value) {
  final normalized = value.replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? 0.0;
}
