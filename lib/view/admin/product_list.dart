import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<Product>>(
          future: productList,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data![index].nombre),
                    subtitle: Text(
                          snapshot.data![index].cantidad.toString(),
                          style: TextStyle(color: snapshot.data![index].cantidad > 10
                                ? Colors.green
                                : snapshot.data![index].cantidad >= 3
                                    ? Colors.yellow
                                    : Colors.red, )),
                    trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductScreen(product: snapshot.data![index])));
                    }),
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
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
            },
            heroTag: 'addProduct',
            tooltip: 'Nuevo Producto',
            child: const Icon(Icons.add),
          ),
        )
      ],
    );
  }
}
