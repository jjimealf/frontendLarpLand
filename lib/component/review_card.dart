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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<User>(
              future: futureUser,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userName = snapshot.data!.name;
                  return _ReviewHeader(
                    userName: userName,
                    rating: widget.review.rating,
                    createdAt: widget.review.createdAt,
                  );
                } else if (snapshot.hasError) {
                  return _ReviewHeader(
                    userName: 'Usuario desconocido',
                    rating: widget.review.rating,
                    createdAt: widget.review.createdAt,
                  );
                }
                return const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              widget.review.comment,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  final String userName;
  final int rating;
  final DateTime? createdAt;

  const _ReviewHeader({
    required this.userName,
    required this.rating,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = userName.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFF3EBD4),
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF2C4432),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C4432),
                ),
              ),
              if (createdAt != null)
                Text(
                  _formatDate(createdAt!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (index) => Icon(
              index < rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: 18,
              color: Colors.amber.shade700,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime value) {
    final now = DateTime.now();
    final localValue = value.toLocal();
    final dateOnly = DateTime(localValue.year, localValue.month, localValue.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    final daysDiff = todayOnly.difference(dateOnly).inDays;
    final hh = localValue.hour.toString().padLeft(2, '0');
    final mm = localValue.minute.toString().padLeft(2, '0');

    if (daysDiff == 0) {
      return 'Hoy, $hh:$mm';
    }
    if (daysDiff == 1) {
      return 'Ayer, $hh:$mm';
    }
    if (daysDiff > 1 && daysDiff < 7) {
      return 'Hace $daysDiff dias';
    }

    final d = localValue.day.toString().padLeft(2, '0');
    final m = localValue.month.toString().padLeft(2, '0');
    final y = localValue.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }
}

