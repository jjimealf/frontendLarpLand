import 'package:flutter/material.dart';
import 'package:larpland/model/product.dart';

class CartProvider with ChangeNotifier {
  final Map<int, Product> _items = {};

  Map<int, Product> get items => {..._items};

  void addProduct(Product product) {
    if (_items.containsKey(product.id)) {
      if (_items[product.id]!.cantidadCarrito < product.cantidad) {
        _items.update(
          product.id,
          (existingProduct) => Product(
            id: existingProduct.id,
            nombre: existingProduct.nombre,
            precio: existingProduct.precio,
            cantidad: existingProduct.cantidad,
            cantidadCarrito: existingProduct.cantidadCarrito + 1, 
            descripcion: existingProduct.descripcion,
            imagen: existingProduct.imagen,
            valoracionTotal: existingProduct.valoracionTotal,
            categoria: existingProduct.categoria,
          ),
        );
      } else {
        throw 'Producto fuera de stock ';
      }
    } else {
      _items.putIfAbsent(
        product.id,
        () => Product(
          id: product.id,
          nombre: product.nombre,
          precio: product.precio,
          cantidad: product.cantidad,
          cantidadCarrito: 1,
          descripcion: product.descripcion,
          imagen: product.imagen,
          valoracionTotal: product.valoracionTotal,
          categoria: product.categoria,
        ),
      );
    }
    notifyListeners();
  }

  void removeProduct(int productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.cantidadCarrito > 1) {
        _items.update(
          productId,
          (existingProduct) => Product(
            id: existingProduct.id,
            nombre: existingProduct.nombre,
            precio: existingProduct.precio,
            cantidad: existingProduct.cantidad,
            cantidadCarrito: existingProduct.cantidadCarrito - 1,
            descripcion: existingProduct.descripcion,
            imagen: existingProduct.imagen,
            valoracionTotal: existingProduct.valoracionTotal,
            categoria: existingProduct.categoria,
          ),
        );
      } else {
        _items.remove(productId);
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, product) {
      total += double.parse(product.precio) * product.cantidadCarrito;
    });
    return total;
  }

  int get totalItemsCount {
    int total = 0;
    for (final product in _items.values) {
      total += product.cantidadCarrito;
    }
    return total;
  }
}
