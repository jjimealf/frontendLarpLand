import 'package:flutter/material.dart';
import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/provider/cart_provider.dart';
import 'package:larpland/util/error_message.dart';
import 'package:larpland/view/cart/checkout.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  final int userId;

  const CartScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Carrito de compras'),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: cart.clearCart,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Vaciar'),
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
        child: cartItems.isEmpty
            ? _EmptyCart(
                onGoCatalog: () => Navigator.pop(context),
              )
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
                              color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    color: const Color(0xFFF3EBD4),
                                    child: SmartNetworkImage(
                                      imagePath: item.imagen,
                                      height: 76,
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
                                          color: Color(0xFF2C4432),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Unitario: ${_formatEuro(unitPrice)}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Total: ${_formatEuro(lineTotal)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _QtyButton(
                                            icon: Icons.remove,
                                            onPressed: () => cart.removeProduct(item.id),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3EBD4),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${item.cantidadCarrito}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          _QtyButton(
                                            icon: Icons.add,
                                            onPressed: () {
                                              try {
                                                cart.addProduct(item);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(uiErrorMessage(e)),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
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
                          color: const Color(0xFF5C3F2D).withValues(alpha: 0.18),
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
                                'Total',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatEuro(cart.totalAmount),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C4432),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CheckoutScreen(userId: userId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.payment_outlined),
                              label: const Text('Continuar al checkout'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2C4432),
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

  static double _parsePrice(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  static String _formatEuro(double value) {
    return '${value.toStringAsFixed(2)} €';
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBD4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: const Color(0xFF2C4432)),
        onPressed: onPressed,
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onGoCatalog;

  const _EmptyCart({required this.onGoCatalog});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.remove_shopping_cart_outlined,
              size: 52,
              color: Color(0xFF8C3C2F),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu carrito esta vacio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C4432),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Agrega productos desde el catalogo para comenzar tu compra.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onGoCatalog,
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Volver al catalogo'),
            ),
          ],
        ),
      ),
    );
  }
}

