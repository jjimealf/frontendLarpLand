import 'dart:io';

import 'package:larpland/model/user_review.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


Future<List<ProductReviews>> fetchProductReviews() async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/reviews'));
  if (response.statusCode == 200) {
    return List<ProductReviews>.from(jsonDecode(response.body).map((review) => ProductReviews.fromJson(review)));
  } else {
    throw Exception('Falló al cargar las reseñas del producto');
  }
}

Future<void> addProductReview(int userId, int productId, String comment, int rating) async {
  final response = await http.post(
    Uri.parse('http://127.0.0.1:8000/api/reviews'),
    body: {
      'userId': userId,
      'productId': productId,
      'comment': comment,
      'rating': rating,
    },
  );

  if (response.statusCode != 200) {
    throw HttpException('${response.reasonPhrase}');
  }
}

Future<List<ProductReviews>> fetchProductReviewsById(int productId) async {
  final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/reviews/$productId'));
  if (response.statusCode == 200) {
    return List<ProductReviews>.from(jsonDecode(response.body).map((review) => ProductReviews.fromJson(review)));
  } else {
    throw HttpException('${response.reasonPhrase}');
  }
}