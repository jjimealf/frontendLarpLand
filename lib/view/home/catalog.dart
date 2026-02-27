import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/provider/cart_provider.dart';
import 'package:larpland/service/product.dart';
import 'package:larpland/util/error_message.dart';
import 'package:larpland/view/cart/cart.dart';
import 'package:larpland/view/product_detail/product_detail.dart';
import 'package:provider/provider.dart';

class CatalogScreen extends StatefulWidget {
  final int userId;

  const CatalogScreen({super.key, required this.userId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const int _pageSize = 12;

  late Future<List<Product>> productsFuture;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  final List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  Timer? _debounce;
  bool _showAdvancedFilters = false;
  bool _onlyInStock = false;
  String _selectedCategory = 'Todas';
  _CatalogSort _sort = _CatalogSort.relevance;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    productsFuture = _loadProducts();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  Future<List<Product>> _loadProducts() async {
    final fetched = await fetchProductList();
    _allProducts
      ..clear()
      ..addAll(fetched);
    _applyFilters();
    return _filteredProducts;
  }

  Future<void> _refreshProducts() async {
    final fetched = await fetchProductList();
    if (!mounted) {
      return;
    }
    setState(() {
      _allProducts
        ..clear()
        ..addAll(fetched);
      _applyFilters();
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _applyFilters);
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    final minPrice = _parseNullablePrice(minPriceController.text);
    final maxPrice = _parseNullablePrice(maxPriceController.text);
    if (!mounted) {
      return;
    }

    setState(() {
      final filtered = _allProducts.where((item) {
        final matchesQuery = query.isEmpty ||
            item.nombre.toLowerCase().contains(query) ||
            item.categoria.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'Todas' ||
            item.categoria.toLowerCase() == _selectedCategory.toLowerCase();
        final matchesStock = !_onlyInStock || item.cantidad > 0;
        final price = _parsePrice(item.precio);
        final matchesMin = minPrice == null || price >= minPrice;
        final matchesMax = maxPrice == null || price <= maxPrice;
        return matchesQuery &&
            matchesCategory &&
            matchesStock &&
            matchesMin &&
            matchesMax;
      }).toList(growable: false);

      _filteredProducts = _sortProducts(filtered);
      _visibleCount = (_filteredProducts.length < _pageSize)
          ? _filteredProducts.length
          : _pageSize;
    });
  }

  List<Product> _sortProducts(List<Product> source) {
    final sorted = List<Product>.from(source);
    switch (_sort) {
      case _CatalogSort.relevance:
        break;
      case _CatalogSort.priceAsc:
        sorted.sort((a, b) => _parsePrice(a.precio).compareTo(_parsePrice(b.precio)));
      case _CatalogSort.priceDesc:
        sorted.sort((a, b) => _parsePrice(b.precio).compareTo(_parsePrice(a.precio)));
      case _CatalogSort.ratingDesc:
        sorted.sort((a, b) => _parseRating(b.valoracionTotal).compareTo(_parseRating(a.valoracionTotal)));
      case _CatalogSort.stockDesc:
        sorted.sort((a, b) => b.cantidad.compareTo(a.cantidad));
      case _CatalogSort.nameAsc:
        sorted.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    }
    return sorted;
  }

  List<Product> get _visibleProducts {
    final end = _visibleCount.clamp(0, _filteredProducts.length);
    return _filteredProducts.take(end).toList(growable: false);
  }

  bool get _canLoadMore => _visibleCount < _filteredProducts.length;

  List<String> get _categories {
    final values = _allProducts
        .map((p) => p.categoria.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['Todas', ...values];
  }

  void _clearAdvancedFilters() {
    setState(() {
      _onlyInStock = false;
      _selectedCategory = 'Todas';
      _sort = _CatalogSort.relevance;
      minPriceController.clear();
      maxPriceController.clear();
    });
    _applyFilters();
  }

  void _loadMore() {
    if (!_canLoadMore) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _filteredProducts.length);
    });
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
    await _refreshProducts();
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

  String _sortLabel(_CatalogSort sort) {
    return switch (sort) {
      _CatalogSort.relevance => 'Relevancia',
      _CatalogSort.priceAsc => 'Precio asc',
      _CatalogSort.priceDesc => 'Precio desc',
      _CatalogSort.ratingDesc => 'Valoracion',
      _CatalogSort.stockDesc => 'Stock',
      _CatalogSort.nameAsc => 'Nombre A-Z',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Catalogo de productos'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: widget.userId),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  cart.items.isEmpty
                      ? Icons.shopping_cart_outlined
                      : Icons.shopping_cart,
                ),
                if (cart.items.isNotEmpty)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        '${cart.totalItemsCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Ver carrito',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EBD4), Color(0xFFE8DABC)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o categoria...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            _applyFilters();
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF5C3F2D).withValues(alpha: 0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF5C3F2D).withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAdvancedFilters = !_showAdvancedFilters;
                            });
                          },
                          icon: Icon(
                            _showAdvancedFilters
                                ? Icons.tune
                                : Icons.tune_outlined,
                          ),
                          label: Text(
                            _showAdvancedFilters
                                ? 'Ocultar filtros'
                                : 'Filtros avanzados',
                          ),
                        ),
                      ),
                      if (_selectedCategory != 'Todas' ||
                          _onlyInStock ||
                          _sort != _CatalogSort.relevance ||
                          minPriceController.text.trim().isNotEmpty ||
                          maxPriceController.text.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearAdvancedFilters,
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ],
                  ),
                  if (_showAdvancedFilters) ...[
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _categories.contains(_selectedCategory)
                                        ? _selectedCategory
                                        : 'Todas',
                                    decoration: _filterDecoration('Categoria'),
                                    items: _categories
                                        .map(
                                          (category) => DropdownMenuItem<String>(
                                            value: category,
                                            child: Text(category),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _selectedCategory = value);
                                      _applyFilters();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<_CatalogSort>(
                                    initialValue: _sort,
                                    decoration: _filterDecoration('Ordenar por'),
                                    items: _CatalogSort.values
                                        .map(
                                          (sort) => DropdownMenuItem<_CatalogSort>(
                                            value: sort,
                                            child: Text(_sortLabel(sort)),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _sort = value);
                                      _applyFilters();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: minPriceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (_) => _applyFilters(),
                                    decoration: _filterDecoration('Precio min'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: maxPriceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (_) => _applyFilters(),
                                    decoration: _filterDecoration('Precio max'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SwitchListTile.adaptive(
                              value: _onlyInStock,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Solo con stock disponible'),
                              onChanged: (value) {
                                setState(() => _onlyInStock = value);
                                _applyFilters();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Color(0xFF2C4432),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No se pudo cargar el catalogo:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  productsFuture = _loadProducts();
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshProducts,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        const horizontalPadding = 12.0;
                        const crossSpacing = 10.0;
                        final crossAxisCount = width >= 1000
                            ? 4
                            : width >= 760
                                ? 3
                                : 2;
                        final availableWidth = width -
                            (horizontalPadding * 2) -
                            ((crossAxisCount - 1) * crossSpacing);
                        final cardWidth = availableWidth / crossAxisCount;
                        final imageHeight = (cardWidth * 0.62).clamp(95.0, 145.0);
                        final textScale =
                            MediaQuery.textScalerOf(context).scale(1.0);
                        final extraHeightForTextScale =
                            ((textScale - 1).clamp(0.0, 0.8)) * 48.0;
                        final baseContentHeight = switch (crossAxisCount) {
                          4 => 208.0,
                          3 => 220.0,
                          _ => 242.0,
                        };
                        final cardMainAxisExtent = imageHeight +
                            baseContentHeight +
                            extraHeightForTextScale;

                        if (_filteredProducts.isEmpty) {
                          return ListView(
                            children: const [
                              SizedBox(height: 120),
                              Icon(
                                Icons.search_off_outlined,
                                size: 44,
                                color: Color(0xFF8C3C2F),
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'No hay productos con ese criterio',
                                  style: TextStyle(
                                    color: Color(0xFF2C4432),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        final visibleProducts = _visibleProducts;
                        final showLoadMoreTile = _canLoadMore;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          itemCount: visibleProducts.length + (showLoadMoreTile ? 1 : 0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: crossSpacing,
                            mainAxisSpacing: 10,
                            mainAxisExtent: cardMainAxisExtent,
                          ),
                          itemBuilder: (context, index) {
                            if (showLoadMoreTile && index == visibleProducts.length) {
                              return _LoadMoreCatalogTile(
                                remaining: _filteredProducts.length - visibleProducts.length,
                                onPressed: _loadMore,
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
                                              'product-thumb-${product.id}-${product.imagen}',
                                            ),
                                            imagePath: product.imagen,
                                            fit: BoxFit.contain,
                                            height: imageHeight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        product.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2C4432),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.categoria,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${product.precio} €',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${product.valoracionTotal} / 5',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: stockColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'Stock: ${product.cantidad}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: stockColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: () {
                                            try {
                                              if (product.cantidad == 0) {
                                                throw 'Producto sin stock';
                                              }
                                              cart.addProduct(product);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${product.nombre} agregado al carrito',
                                                  ),
                                                  duration:
                                                      const Duration(milliseconds: 900),
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(uiErrorMessage(e)),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.add_shopping_cart),
                                          label: const Text('Agregar'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF2C4432),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            minimumSize: const Size.fromHeight(38),
                                          ),
                                        ),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _parsePrice(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  static double? _parseNullablePrice(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  static double _parseRating(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }
}

enum _CatalogSort {
  relevance,
  priceAsc,
  priceDesc,
  ratingDesc,
  stockDesc,
  nameAsc,
}

class _LoadMoreCatalogTile extends StatelessWidget {
  final int remaining;
  final VoidCallback onPressed;

  const _LoadMoreCatalogTile({
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

