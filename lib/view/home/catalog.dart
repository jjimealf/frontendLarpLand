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

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _filterProducts);
  }

  void _filterProducts() {
    final query = searchController.text.trim().toLowerCase();
    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List<Product>.from(_allProducts);
      } else {
        _filteredProducts = _allProducts
            .where((item) => item.nombre.toLowerCase().contains(query))
            .toList(growable: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Catalogo de Productos'),
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
            icon: const Icon(Icons.shopping_cart),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FutureBuilder<List<Product>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return GestureDetector(
                          key: ValueKey(product.id),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetail(
                                  product: product,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SmartNetworkImage(
                                    imagePath: product.imagen,
                                    fit: BoxFit.cover,
                                    height: 110,
                                  ),
                                ),
                                Text(product.nombre),
                                Text(product.precio),
                                ElevatedButton(
                                  onPressed: () {
                                    try {
                                      if (product.cantidad == 0) {
                                        throw 'Producto sin stock';
                                      }
                                      cart.addProduct(product);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString()),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Agregar al carrito'),
                                ),
                              ],
                            ),
                          ),
                        );
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
            ),
          ],
        ),
      ),
    );
  }
}
