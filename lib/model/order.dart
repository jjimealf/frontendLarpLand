class UserOrder {
  final int id;
  final int userId;
  final double totalAmount;
  final int totalItems;
  final String status;
  final DateTime? createdAt;
  final List<UserOrderItem> items;

  const UserOrder({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.totalItems,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final userId = _asInt(json['user_id'] ?? json['userId']);
    final totalAmount = _asDouble(json['total_amount'] ?? json['totalAmount']);
    final totalItems = _asInt(json['total_items'] ?? json['totalItems']);
    final status = _asString(json['status']);
    final createdAt =
        _asDateTime(json['created_at'] ?? json['createdAt'] ?? json['fecha']);
    final rawItems = json['items'];

    if (id == null ||
        userId == null ||
        totalAmount == null ||
        totalItems == null ||
        status == null) {
      throw const FormatException('Fallo al cargar el pedido');
    }

    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(UserOrderItem.fromJson)
            .toList(growable: false)
        : const <UserOrderItem>[];

    return UserOrder(
      id: id,
      userId: userId,
      totalAmount: totalAmount,
      totalItems: totalItems,
      status: status,
      createdAt: createdAt,
      items: items,
    );
  }
}

class UserOrderItem {
  final int productId;
  final String productName;
  final String unitPrice;
  final int quantity;
  final double lineTotal;
  final String imageUrl;

  const UserOrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.imageUrl,
  });

  factory UserOrderItem.fromJson(Map<String, dynamic> json) {
    final productId = _asInt(json['product_id'] ?? json['productId']) ?? 0;
    final productName =
        _asString(json['product_name'] ?? json['productName']) ?? '';
    final unitPrice = _asString(json['unit_price'] ?? json['unitPrice']) ?? '0';
    final quantity = _asInt(json['quantity']) ?? 0;
    final lineTotal = _asDouble(json['line_total'] ?? json['lineTotal']) ?? 0;
    final imageUrl = _asString(json['image_url'] ?? json['imageUrl']) ?? '';

    return UserOrderItem(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity,
      lineTotal: lineTotal,
      imageUrl: imageUrl,
    );
  }
}

int? _asInt(dynamic value) {
  return switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v),
    _ => null,
  };
}

double? _asDouble(dynamic value) {
  return switch (value) {
    double v => v,
    num v => v.toDouble(),
    String v => double.tryParse(v.replaceAll(',', '.')),
    _ => null,
  };
}

String? _asString(dynamic value) {
  return switch (value) {
    String v => v,
    num v => v.toString(),
    bool v => v.toString(),
    _ => null,
  };
}

DateTime? _asDateTime(dynamic value) {
  final raw = _asString(value);
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}
