import 'package:flutter/material.dart';
import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/provider/cart_provider.dart';
import 'package:larpland/service/order.dart';
import 'package:larpland/service/product.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatelessWidget {
  final int userId;

  const CheckoutScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEFF4FA)],
          ),
        ),
        child: cartItems.isEmpty
            ? const _EmptyCheckout()
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final unitPrice = _parsePrice(item.precio);
                        final lineTotal = unitPrice * item.cantidadCarrito;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.blueGrey.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 66,
                                    height: 66,
                                    color: const Color(0xFFF1F5F9),
                                    child: SmartNetworkImage(
                                      imagePath: item.imagen,
                                      height: 66,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1D3557),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.cantidadCarrito} x ${_formatEuro(unitPrice)}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatEuro(lineTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D3557),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.blueGrey.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Total a pagar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatEuro(cart.totalAmount),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1D3557),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _confirmOrder(context, cart),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Realizar pedido'),
                              style: FilledButton.styleFrom(
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
                ],
              ),
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context, CartProvider cart) async {
    final updatedStocks = <int, int>{};
    int? orderId;

    try {
      final cartItems = cart.items.values.toList(growable: false);
      for (final item in cartItems) {
        final newStock = item.cantidad - item.cantidadCarrito;
        if (newStock < 0) {
          throw Exception(
            'Stock insuficiente para "${item.nombre}". '
            'Disponible: ${item.cantidad}, en carrito: ${item.cantidadCarrito}',
          );
        }
        await updateProduct(item.id, stock: newStock);
        updatedStocks[item.id] = item.cantidad;
      }
      orderId = await createUserOrder(userId: userId, cartItems: cartItems);
    } catch (e) {
      for (final entry in updatedStocks.entries) {
        try {
          await updateProduct(entry.key, stock: entry.value);
        } catch (_) {
          // Ignore rollback errors to preserve original failure visibility.
        }
      }

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar el pedido: $e'),
        ),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pedido realizado'),
          content: Text(
            orderId == null
                ? 'Gracias por su compra.'
                : 'Gracias por su compra. Pedido #$orderId registrado.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                cart.clearCart();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static double _parsePrice(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  static String _formatEuro(double value) {
    return '${value.toStringAsFixed(2)} €';
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 50,
              color: Color(0xFF457B9D),
            ),
            SizedBox(height: 10),
            Text(
              'No hay productos para checkout',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D3557),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
