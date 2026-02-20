import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/provider/cart_provider.dart';
import 'package:larpland/service/product.dart';
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
  late Future<List<Product>> productsFuture;
  final TextEditingController searchController = TextEditingController();
  final List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  Timer? _debounce;

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
    super.dispose();
  }

  Future<List<Product>> _loadProducts() async {
    final fetched = await fetchProductList();
    _allProducts
      ..clear()
      ..addAll(fetched);
    _filteredProducts = List<Product>.from(_allProducts);
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
      _filterProducts(immediate: true);
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _filterProducts);
  }

  void _filterProducts({bool immediate = false}) {
    final query = searchController.text.trim().toLowerCase();
    if (!mounted) {
      return;
    }

    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List<Product>.from(_allProducts);
      } else {
        _filteredProducts = _allProducts
            .where(
              (item) => item.nombre.toLowerCase().contains(query) ||
                  item.categoria.toLowerCase().contains(query),
            )
            .toList(growable: false);
      }
    });

    if (!immediate && query.isNotEmpty && _filteredProducts.isEmpty) {
      // keep quiet state; no snackbar noise while typing.
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
    await _refreshProducts();
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
                  builder: (context) => const CartScreen(),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Ver carrito',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEFF4FA)],
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
                            _filterProducts(immediate: true);
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.blueGrey.withValues(alpha: 0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.blueGrey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
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
                              color: Color(0xFF1D3557),
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
                        const contentHeight = 170.0;
                        final computedRatio = cardWidth / (imageHeight + contentHeight);
                        final childAspectRatio = crossAxisCount <= 2
                            ? computedRatio.clamp(0.52, 0.58)
                            : computedRatio.clamp(0.58, 0.66);

                        if (_filteredProducts.isEmpty) {
                          return ListView(
                            children: const [
                              SizedBox(height: 120),
                              Icon(
                                Icons.search_off_outlined,
                                size: 44,
                                color: Color(0xFF457B9D),
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'No hay productos con ese criterio',
                                  style: TextStyle(
                                    color: Color(0xFF1D3557),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          itemCount: _filteredProducts.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: crossSpacing,
                            mainAxisSpacing: 10,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
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
                                          color: Color(0xFF1D3557),
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
                                        product.precio,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    stockColor.withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(999),
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
                                                SnackBar(content: Text(e.toString())),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.add_shopping_cart),
                                          label: const Text('Agregar'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF1D3557),
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
}
