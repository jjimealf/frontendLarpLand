import 'package:flutter/material.dart';

import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/service/product.dart';
import 'package:larpland/view/admin/product_register.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late Future<List<Product>> productList;

  @override
  void initState() {
    super.initState();
    productList = fetchProductList();
  }

  Future<void> _openProductForm({Product? product}) async {
    final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    );

    if (changed == true && mounted) {
      setState(() {
        productList = fetchProductList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<Product>>(
          future: productList,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  message: 'Sin productos',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const horizontalPadding = 14.0;
                  const crossSpacing = 12.0;
                  final crossAxisCount = width >= 1000
                      ? 4
                      : width >= 700
                          ? 3
                          : 2;
                  final availableWidth = width -
                      (horizontalPadding * 2) -
                      ((crossAxisCount - 1) * crossSpacing);
                  final cardWidth = availableWidth / crossAxisCount;
                  final imageHeight = (cardWidth * 0.72).clamp(96.0, 170.0);
                  const contentHeight = 108.0;
                  final computedAspectRatio =
                      cardWidth / (imageHeight + contentHeight);
                  final childAspectRatio = crossAxisCount <= 2
                      ? computedAspectRatio.clamp(0.50, 0.58)
                      : computedAspectRatio.clamp(0.56, 0.66);
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: crossSpacing,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final product = snapshot.data![index];
                      final stockColor = product.cantidad > 10
                          ? Colors.green
                          : product.cantidad >= 3
                              ? Colors.orange
                              : Colors.red;

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.blueGrey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: SmartNetworkImage(
                                    imagePath: product.imagen,
                                    height: imageHeight,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                product.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.categoria,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: stockColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Stock: ${product.cantidad}',
                                          style: TextStyle(
                                            color: stockColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _openProductForm(product: product),
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 36,
                                      height: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              return const _EmptyState(
                icon: Icons.error_outline,
                message: 'No se pudieron cargar productos',
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _openProductForm,
            backgroundColor: const Color(0xFF1D3557),
            foregroundColor: Colors.white,
            heroTag: 'addProduct',
            tooltip: 'Nuevo Producto',
            child: const Icon(Icons.add),
          ),
        )
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF457B9D)),
          const SizedBox(height: 8),
          Text(
            message,
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
