import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:larpland/model/order.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/service/firebase_backend.dart';

Future<int> createUserOrder({
  required int userId,
  required List<Product> cartItems,
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

  final totalAmount = normalizedItems.fold<double>(
    0,
    (acc, item) => acc + ((item['line_total'] as num?)?.toDouble() ?? 0),
  );
  final totalItems = normalizedItems.fold<int>(
    0,
    (acc, item) => acc + ((item['quantity'] as num?)?.toInt() ?? 0),
  );

  await FirebaseBackend.firestore.collection('orders').add(<String, dynamic>{
    'id': orderId,
    'user_id': userId,
    'status': 'completed',
    'total_amount': totalAmount,
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

double _parsePrice(String value) {
  final normalized = value.replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? 0.0;
}
