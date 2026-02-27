import 'package:flutter/material.dart';

import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/service/product.dart';
import 'package:larpland/view/product_detail/product_detail.dart';
import 'package:larpland/view/admin/product_register.dart';

class ProductList extends StatefulWidget {
  final int userId;

  const ProductList({super.key, required this.userId});

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

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar producto'),
        content: Text('Â¿Seguro que quieres borrar "${product.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await deleteProduct(product.id);
      if (!mounted) {
        return;
      }
      setState(() {
        productList = fetchProductList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto borrado correctamente')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el producto: $e')),
      );
    }
  }

  Future<void> _openProductDetail(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetail(
          product: product,
          userId: widget.userId,
        ),
      ),
    );
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
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(1.0);
                  final extraHeightForTextScale =
                      ((textScale - 1).clamp(0.0, 0.8)) * 36.0;
                  final baseContentHeight = switch (crossAxisCount) {
                    4 => 124.0,
                    3 => 136.0,
                    _ => 156.0,
                  };
                  final cardMainAxisExtent = imageHeight +
                      baseContentHeight +
                      extraHeightForTextScale;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: crossSpacing,
                      mainAxisSpacing: 12,
                      mainAxisExtent: cardMainAxisExtent,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final product = snapshot.data![index];
                      final stockColor = product.cantidad > 10
                          ? Colors.green
                          : product.cantidad >= 3
                              ? Colors.orange
                              : Colors.red;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openProductDetail(product),
                        child: Card(
                          elevation: 0,
                          color: const Color(0xFFFFFAF0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
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
                                    color: const Color(0xFFF3EBD4),
                                    child: SmartNetworkImage(
                                      key: ValueKey(
                                        'admin-product-thumb-${product.id}-${product.imagen}',
                                      ),
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
                                    PopupMenuButton<String>(
                                      tooltip: 'Acciones',
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _openProductForm(product: product);
                                        } else if (value == 'delete') {
                                          _deleteProduct(product);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Editar'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Borrar',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      icon: const Icon(Icons.more_vert),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
            backgroundColor: const Color(0xFF2C4432),
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
          Icon(icon, size: 40, color: const Color(0xFF8C3C2F)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF2C4432),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

