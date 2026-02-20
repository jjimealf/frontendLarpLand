class ProductReviews {
  final int id;
  final int userId;
  final int productId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  ProductReviews({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ProductReviews.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final userId = _asInt(json['user_id'] ?? json['userId']);
    final productId = _asInt(json['product_id'] ?? json['productId']);
    final rating = _asInt(json['rating']);
    final comment = _asString(json['comment']);
    final createdAt = _asDateTime(
      json['created_at'] ?? json['createdAt'] ?? json['fecha_creacion'],
    );

    if (id == null ||
        userId == null ||
        productId == null ||
        rating == null ||
        comment == null) {
      throw const FormatException('Fallo al cargar la resena del producto');
    }

    return ProductReviews(
      id: id,
      userId: userId,
      productId: productId,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
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
