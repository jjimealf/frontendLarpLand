import 'package:flutter/material.dart';
import 'package:larpland/model/user.dart';
import 'package:larpland/model/user_review.dart';
import 'package:larpland/service/user.dart';

class ReviewCard extends StatefulWidget {
  final ProductReviews review;

  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  static final Map<int, Future<User>> _userFutureCache = {};

  late Future<User> futureUser;

  @override
  void initState() {
    super.initState();
    futureUser = _userFutureCache.putIfAbsent(
      widget.review.userId,
      () => showUser(widget.review.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<User>(
              future: futureUser,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
                } else if (snapshot.hasError) {
                  return const Text(
                    'Unknown User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 4),
            Text(
              widget.review.comment,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                widget.review.rating,
                (index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
