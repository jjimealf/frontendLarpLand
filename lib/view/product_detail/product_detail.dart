import 'package:flutter/material.dart';
import 'package:larpland/component/review_card.dart';
import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/model/user_review.dart';
import 'package:larpland/service/product.dart';
import 'package:larpland/service/user_review.dart';

class ProductDetail extends StatefulWidget {
  final Product product;
  final int userId;

  const ProductDetail({super.key, required this.product, required this.userId});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  late Future<List<ProductReviews>> futureProductReviews;

  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 1;
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    futureProductReviews = fetchProductReviewsById(widget.product.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.nombre),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEFF4FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductHeader(),
                const SizedBox(height: 12),
                _buildReviewsSection(),
                const SizedBox(height: 12),
                _buildReviewForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 220,
                color: const Color(0xFFF1F5F9),
                child: SmartNetworkImage(
                  imagePath: widget.product.imagen,
                  fit: BoxFit.contain,
                  height: 220,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.product.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D3557),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.sell_outlined,
                  text: 'Precio: ${widget.product.precio}',
                ),
                _InfoChip(
                  icon: Icons.inventory_2_outlined,
                  text: 'Stock: ${widget.product.cantidad}',
                ),
                _InfoChip(
                  icon: Icons.category_outlined,
                  text: widget.product.categoria,
                ),
                _InfoChip(
                  icon: Icons.star_outline,
                  text: 'Valoracion: ${widget.product.valoracionTotal}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comentarios y valoraciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D3557),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<ProductReviews>>(
              future: futureProductReviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final reviews = snapshot.data ?? const <ProductReviews>[];
                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Todavia no hay resenas para este producto.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return Column(
                  children: reviews
                      .map(
                        (review) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ReviewCard(review: review),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Anade una resena',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D3557),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduce un comentario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _rating,
                decoration: const InputDecoration(
                  labelText: 'Valoracion',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (index) => index + 1)
                    .map(
                      (rating) => DropdownMenuItem<int>(
                        value: rating,
                        child: Text('$rating'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _rating = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmittingReview ? null : _addReview,
                  icon: _isSubmittingReview
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_isSubmittingReview ? 'Enviando...' : 'Enviar resena'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D3557),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addReview() {
    _submitReview();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final reviews = await futureProductReviews;
      if (reviews.any((element) => element.userId == widget.userId)) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya has enviado una resena.')),
        );
        return;
      }

      await addProductReview(
        widget.userId,
        widget.product.id,
        _commentController.text,
        _rating,
      );

      final updatedReviews = await fetchProductReviewsById(widget.product.id);
      await _calculateAverageRating(updatedReviews);

      if (!mounted) {
        return;
      }
      setState(() {
        futureProductReviews = Future.value(updatedReviews);
      });
      _commentController.clear();
      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  Future<void> _calculateAverageRating(List<ProductReviews> reviews) async {
    if (reviews.isEmpty) {
      return;
    }
    final average =
        reviews.fold(0, (sum, item) => sum + item.rating) / reviews.length;
    await updateProduct(
      widget.product.id,
      valoracionTotal: average.toString(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1D3557)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1D3557),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
