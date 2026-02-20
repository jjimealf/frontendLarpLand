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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SmartNetworkImage(
                  imagePath: widget.product.imagen,
                  fit: BoxFit.cover,
                  height: 120,
                  width: 220,
                ),
              ),
              Text(widget.product.nombre),
              Text(widget.product.precio),
              Text(widget.product.valoracionTotal),
              const Text(
                'Comentarios y Valoraciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<ProductReviews>>(
                future: futureProductReviews,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return ReviewCard(review: snapshot.data![index]);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
              const Divider(height: 32, thickness: 2),
              const Text(
                'Anade una resena',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comentario',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce un comentario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Valoracion'),
                    DropdownButtonFormField<int>(
                      initialValue: _rating,
                      items: List.generate(5, (index) => index + 1)
                          .map((rating) => DropdownMenuItem<int>(
                                value: rating,
                                child: Text('$rating'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _rating = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addReview,
                      child: const Text('Enviar resena'),
                    ),
                  ],
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
    if (!_formKey.currentState!.validate()) return;

    try {
      final reviews = await futureProductReviews;
      if (reviews.any((element) => element.userId == widget.userId)) {
        if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        futureProductReviews = Future.value(updatedReviews);
      });
      _commentController.clear();
      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _calculateAverageRating(List<ProductReviews> reviews) async {
    if (reviews.isEmpty) return;
    final average =
        reviews.fold(0, (sum, item) => sum + item.rating) / reviews.length;
    await updateProduct(
      widget.product.id,
      valoracionTotal: average.toString(),
    );
  }
}
