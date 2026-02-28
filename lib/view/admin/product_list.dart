import 'package:flutter/material.dart';

import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/service/product.dart';
import 'package:larpland/util/error_message.dart';
import 'package:larpland/view/admin/product_register.dart';
import 'package:larpland/view/product_detail/product_detail.dart';

class ProductList extends StatefulWidget {
  final int userId;

  const ProductList({super.key, required this.userId});

  @override
  State<ProductList> createState() => _ProductListState();
}

enum _ProductStockFilter { all, inStock, lowStock, outOfStock }

class _ProductListState extends State<ProductList> {
  static const int _pageSize = 12;
  late Future<List<Product>> productList;
  final TextEditingController _searchController = TextEditingController();
  _ProductStockFilter _stockFilter = _ProductStockFilter.all;
  String _categoryFilter = 'Todas';
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    productList = fetchProductList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = fetchProductList();
    setState(() {
      productList = future;
      _visibleCount = _pageSize;
    });
    await future;
  }

  List<String> _categoriesFor(List<Product> products) {
    final values = products
        .map((product) => product.categoria.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['Todas', ...values];
  }

  void _resetPagination() {
    _visibleCount = _pageSize;
  }

  void _loadMore(int total) {
    if (_visibleCount >= total) {
      return;
    }
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, total);
    });
  }

  String _stockFilterLabel(_ProductStockFilter value) {
    return switch (value) {
      _ProductStockFilter.all => 'Todo',
      _ProductStockFilter.inStock => 'Con stock',
      _ProductStockFilter.lowStock => 'Stock bajo',
      _ProductStockFilter.outOfStock => 'Sin stock',
    };
  }

  List<Product> _applyFilters(
    List<Product> products, {
    required String activeCategory,
  }) {
    final query = _searchController.text.trim().toLowerCase();
    return products.where((product) {
      final matchesQuery = query.isEmpty
          ? true
          : product.nombre.toLowerCase().contains(query) ||
              product.categoria.toLowerCase().contains(query) ||
              '${product.id}'.contains(query);

      final matchesCategory = activeCategory == 'Todas'
          ? true
          : product.categoria.toLowerCase() == activeCategory.toLowerCase();

      final matchesStock = switch (_stockFilter) {
        _ProductStockFilter.all => true,
        _ProductStockFilter.inStock => product.cantidad > 0,
        _ProductStockFilter.lowStock => product.cantidad > 0 && product.cantidad <= 5,
        _ProductStockFilter.outOfStock => product.cantidad <= 0,
      };

      return matchesQuery && matchesCategory && matchesStock;
    }).toList(growable: false);
  }

  Future<void> _openProductForm({Product? product}) async {
    final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    );

    if (changed == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar producto'),
        content: Text('Seguro que quieres borrar "${product.nombre}"?'),
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
      await _refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto borrado correctamente')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el producto: ${uiErrorMessage(e)}')),
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: uiErrorMessage(snapshot.error!),
                onRetry: _refresh,
              );
            }

            final allProducts = snapshot.data ?? const <Product>[];
            final categories = _categoriesFor(allProducts);
            final activeCategory =
                categories.contains(_categoryFilter) ? _categoryFilter : 'Todas';
            final filteredProducts = _applyFilters(
              allProducts,
              activeCategory: activeCategory,
            );
            final hasFilters = _searchController.text.trim().isNotEmpty ||
                _stockFilter != _ProductStockFilter.all ||
                activeCategory != 'Todas';
            final visibleEnd = _visibleCount.clamp(0, filteredProducts.length);
            final visibleProducts = filteredProducts.take(visibleEnd).toList(growable: false);
            final canLoadMore = _visibleCount < filteredProducts.length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() => _resetPagination()),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre, categoria o ID...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _resetPagination());
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Recargar',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Card(
                    elevation: 0,
                    color: const Color(0xFFFFFAF0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<_ProductStockFilter>(
                              initialValue: _stockFilter,
                              isExpanded: true,
                              decoration: _filterDecoration('Stock'),
                              items: _ProductStockFilter.values
                                  .map(
                                    (value) => DropdownMenuItem<_ProductStockFilter>(
                                      value: value,
                                      child: Text(_stockFilterLabel(value)),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _stockFilter = value;
                                  _resetPagination();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: activeCategory,
                              isExpanded: true,
                              decoration: _filterDecoration('Categoria'),
                              items: categories
                                  .map(
                                    (category) => DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _categoryFilter = value;
                                  _resetPagination();
                                });
                              },
                            ),
                          ),
                          if (hasFilters) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _stockFilter = _ProductStockFilter.all;
                                  _categoryFilter = 'Todas';
                                  _resetPagination();
                                });
                              },
                              child: const Text('Limpiar'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            _EmptyState(
                              icon: hasFilters
                                  ? Icons.search_off_outlined
                                  : Icons.inventory_2_outlined,
                              message: hasFilters
                                  ? 'No hay productos con esos filtros'
                                  : 'Sin productos',
                            ),
                          ],
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: LayoutBuilder(
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
                              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                              final extraHeightForTextScale =
                                  ((textScale - 1).clamp(0.0, 0.8)) * 36.0;
                              final baseContentHeight = switch (crossAxisCount) {
                                4 => 124.0,
                                3 => 136.0,
                                _ => 156.0,
                              };
                              final cardMainAxisExtent =
                                  imageHeight + baseContentHeight + extraHeightForTextScale;

                              return GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: crossSpacing,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: cardMainAxisExtent,
                                ),
                                itemCount: visibleProducts.length + (canLoadMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (canLoadMore && index == visibleProducts.length) {
                                    return _LoadMoreGridTile(
                                      remaining: filteredProducts.length - visibleProducts.length,
                                      onPressed: () => _loadMore(filteredProducts.length),
                                    );
                                  }

                                  final product = visibleProducts[index];
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
                          ),
                        ),
                ),
              ],
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
        ),
      ],
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _LoadMoreGridTile extends StatelessWidget {
  final int remaining;
  final VoidCallback onPressed;

  const _LoadMoreGridTile({
    required this.remaining,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.expand_more_rounded,
                size: 34,
                color: Color(0xFF2C4432),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cargar mas',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C4432),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$remaining producto(s) restantes',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFF2C4432)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
