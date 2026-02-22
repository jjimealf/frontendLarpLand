import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:larpland/model/user_review.dart';
import 'package:larpland/service/firebase_backend.dart';

Future<List<ProductReviews>> fetchProductReviews() async {
  FirebaseBackend.ensureInitialized();
  final snapshot = await FirebaseBackend.reviews.get();
  return _mapReviewDocs(snapshot.docs);
}

Future<void> addProductReview(
  int userId,
  int productId,
  String comment,
  int rating,
) async {
  FirebaseBackend.ensureInitialized();
  final reviewId = await FirebaseBackend.nextNumericId('reviews');
  await FirebaseBackend.reviews.add(<String, dynamic>{
    'id': reviewId,
    'user_id': userId,
    'product_id': productId,
    'comment': comment.trim(),
    'rating': rating,
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  });
}

Future<List<ProductReviews>> fetchProductReviewsById(int productId) async {
  FirebaseBackend.ensureInitialized();
  final snapshot = await FirebaseBackend.reviews
      .where('product_id', isEqualTo: productId)
      .get();
  return _mapReviewDocs(snapshot.docs);
}

List<ProductReviews> _mapReviewDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final reviews = docs
      .map(FirebaseBackend.normalizeSnapshotData)
      .map((data) {
        final createdAt = data['created_at'];
        if (createdAt is Timestamp) {
          data['created_at'] = createdAt.toDate().toIso8601String();
        }
        return data;
      })
      .map(ProductReviews.fromJson)
      .toList(growable: false);

  final sorted = List<ProductReviews>.from(reviews);
  sorted.sort((a, b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return sorted;
}
