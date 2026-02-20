import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:larpland/model/user_review.dart';
import 'package:larpland/service/api_config.dart';
import 'package:larpland/service/auth_session.dart';

Future<List<ProductReviews>> fetchProductReviews() async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/reviews'),
    headers: _jsonHeaders(),
  );
  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final items = _extractReviewList(decoded);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ProductReviews.fromJson)
        .toList(growable: false);
  }

  throw Exception(
    'Fallo al cargar las resenas (${response.statusCode}): ${response.body}',
  );
}

Future<void> addProductReview(
  int userId,
  int productId,
  String comment,
  int rating,
) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/reviews'),
    headers: _jsonHeaders(),
    body: {
      'userId': userId.toString(),
      'productId': productId.toString(),
      'comment': comment,
      'rating': rating.toString(),
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Fallo al guardar la resena (${response.statusCode}): ${response.body}',
    );
  }
}

Future<List<ProductReviews>> fetchProductReviewsById(int productId) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/reviews/$productId'),
    headers: _jsonHeaders(),
  );
  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final items = _extractReviewList(decoded);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ProductReviews.fromJson)
        .toList(growable: false);
  }

  throw Exception(
    'Fallo al cargar resenas (${response.statusCode}): ${response.body}',
  );
}

Map<String, String> _jsonHeaders() {
  final headers = <String, String>{
    'Accept': 'application/json',
  };
  final token = AuthSession.token;
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}

List<dynamic> _extractReviewList(dynamic decoded) {
  if (decoded is List) {
    return decoded;
  }
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'];
    if (data is List) {
      return data;
    }
    final reviews = decoded['reviews'];
    if (reviews is List) {
      return reviews;
    }
  }
  return const [];
}
