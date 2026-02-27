import 'package:flutter/material.dart';
import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/product.dart';
import 'package:larpland/provider/cart_provider.dart';
import 'package:larpland/service/order.dart';
import 'package:larpland/service/product.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final int userId;

  const CheckoutScreen({super.key, required this.userId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum _PaymentMethod { card, bizum, cashOnDelivery }

enum _DeliveryMethod { standard, express, pickup }

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();

  _PaymentMethod _paymentMethod = _PaymentMethod.card;
  _DeliveryMethod _deliveryMethod = _DeliveryMethod.standard;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList(growable: false);
    final subtotal = _calculateSubtotal(cartItems);
    final shipping = _shippingCostFor(_deliveryMethod, subtotal);
    final total = subtotal + shipping;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
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
            ? const _EmptyCheckout()
            : Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        children: [
                          _CheckoutSection(
                            title: 'Resumen del pedido',
                            child: Column(
                              children: cartItems
                                  .map((item) => _CheckoutLineItem(item: item))
                                  .toList(growable: false),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CheckoutSection(
                            title: 'Datos de contacto',
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _inputDecoration(
                                    'Nombre completo',
                                    Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu nombre';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration(
                                    'Telefono',
                                    Icons.phone_outlined,
                                  ),
                                  validator: (value) {
                                    final raw = value?.trim() ?? '';
                                    if (raw.isEmpty) {
                                      return 'Ingresa tu telefono';
                                    }
                                    if (raw.length < 7) {
                                      return 'Telefono no valido';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CheckoutSection(
                            title: 'Entrega',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DeliverySelector(
                                  value: _deliveryMethod,
                                  subtotal: subtotal,
                                  onChanged: (value) {
                                    setState(() => _deliveryMethod = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                if (_deliveryMethod != _DeliveryMethod.pickup) ...[
                                  TextFormField(
                                    controller: _addressController,
                                    decoration: _inputDecoration(
                                      'Direccion',
                                      Icons.home_outlined,
                                    ),
                                    validator: (value) {
                                      if (_deliveryMethod == _DeliveryMethod.pickup) {
                                        return null;
                                      }
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Ingresa la direccion';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _address2Controller,
                                    decoration: _inputDecoration(
                                      'Piso / puerta (opcional)',
                                      Icons.apartment_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _cityController,
                                          decoration: _inputDecoration(
                                            'Ciudad',
                                            Icons.location_city_outlined,
                                          ),
                                          validator: (value) {
                                            if (_deliveryMethod ==
                                                _DeliveryMethod.pickup) {
                                              return null;
                                            }
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Ingresa ciudad';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _postalCodeController,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration(
                                            'CP',
                                            Icons.markunread_mailbox_outlined,
                                          ),
                                          validator: (value) {
                                            if (_deliveryMethod ==
                                                _DeliveryMethod.pickup) {
                                              return null;
                                            }
                                            final raw = value?.trim() ?? '';
                                            if (raw.isEmpty) {
                                              return 'CP';
                                            }
                                            if (raw.length < 4) {
                                              return 'CP invalido';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else
                                  const _PickupInfo(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CheckoutSection(
                            title: 'Pago',
                            child: Column(
                              children: [
                                _PaymentMethodTile(
                                  value: _PaymentMethod.card,
                                  groupValue: _paymentMethod,
                                  title: 'Tarjeta',
                                  subtitle: 'Pago inmediato (simulado)',
                                  icon: Icons.credit_card_outlined,
                                  onChanged: (value) =>
                                      setState(() => _paymentMethod = value),
                                ),
                                _PaymentMethodTile(
                                  value: _PaymentMethod.bizum,
                                  groupValue: _paymentMethod,
                                  title: 'Bizum',
                                  subtitle: 'Confirmacion instantanea (simulado)',
                                  icon: Icons.phone_android_outlined,
                                  onChanged: (value) =>
                                      setState(() => _paymentMethod = value),
                                ),
                                _PaymentMethodTile(
                                  value: _PaymentMethod.cashOnDelivery,
                                  groupValue: _paymentMethod,
                                  title: 'Contra reembolso',
                                  subtitle: 'Pago al recibir el pedido',
                                  icon: Icons.local_shipping_outlined,
                                  onChanged: (value) =>
                                      setState(() => _paymentMethod = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CheckoutSection(
                            title: 'Notas del pedido',
                            child: TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: _inputDecoration(
                                'Indicaciones para la entrega (opcional)',
                                Icons.note_alt_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _CheckoutFooter(
                    subtotal: subtotal,
                    shipping: shipping,
                    total: total,
                    isSubmitting: _isSubmitting,
                    onConfirm: () => _confirmOrder(
                      context,
                      cart,
                      cartItems,
                      subtotal,
                      shipping,
                      total,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF5C3F2D).withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Future<void> _confirmOrder(
    BuildContext context,
    CartProvider cart,
    List<Product> cartItems,
    double subtotal,
    double shipping,
    double total,
  ) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final updatedStocks = <int, int>{};
    int? orderId;

    try {
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

      orderId = await createUserOrder(
        userId: widget.userId,
        cartItems: cartItems,
        subtotalAmount: subtotal,
        shippingAmount: shipping,
        totalAmount: total,
        status: _paymentMethod == _PaymentMethod.cashOnDelivery
            ? 'pending'
            : 'completed',
        paymentMethod: _paymentMethodCode(_paymentMethod),
        deliveryMethod: _deliveryMethodCode(_deliveryMethod),
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
        shippingAddress: _deliveryMethod == _DeliveryMethod.pickup
            ? <String, dynamic>{
                'mode': 'pickup',
                'location': 'Tienda LarpLand',
              }
            : <String, dynamic>{
                'mode': 'delivery',
                'line1': _addressController.text.trim(),
                'line2': _address2Controller.text.trim(),
                'city': _cityController.text.trim(),
                'postal_code': _postalCodeController.text.trim(),
              },
      );
    } catch (e) {
      for (final entry in updatedStocks.entries) {
        try {
          await updateProduct(entry.key, stock: entry.value);
        } catch (_) {
          // Keep original error visible.
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar el pedido: $e')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pedido confirmado'),
        content: Text(
          orderId == null
              ? 'Tu compra fue registrada correctamente.'
              : 'Tu compra fue registrada correctamente.\nPedido #$orderId',
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
      ),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  double _calculateSubtotal(List<Product> cartItems) {
    return cartItems.fold<double>(0, (acc, item) {
      return acc + (_parsePrice(item.precio) * item.cantidadCarrito);
    });
  }

  double _shippingCostFor(_DeliveryMethod method, double subtotal) {
    switch (method) {
      case _DeliveryMethod.pickup:
        return 0;
      case _DeliveryMethod.standard:
        return subtotal >= 80 ? 0 : 4.99;
      case _DeliveryMethod.express:
        return 9.99;
    }
  }

  String _paymentMethodCode(_PaymentMethod value) {
    return switch (value) {
      _PaymentMethod.card => 'card',
      _PaymentMethod.bizum => 'bizum',
      _PaymentMethod.cashOnDelivery => 'cash_on_delivery',
    };
  }

  String _deliveryMethodCode(_DeliveryMethod value) {
    return switch (value) {
      _DeliveryMethod.standard => 'standard',
      _DeliveryMethod.express => 'express',
      _DeliveryMethod.pickup => 'pickup',
    };
  }

  static double _parsePrice(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }
}

class _CheckoutSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _CheckoutSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF2C4432),
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _CheckoutLineItem extends StatelessWidget {
  final Product item;

  const _CheckoutLineItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final unitPrice = _parsePrice(item.precio);
    final lineTotal = unitPrice * item.cantidadCarrito;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              color: const Color(0xFFF3EBD4),
              child: SmartNetworkImage(
                key: ValueKey('checkout-${item.id}-${item.imagen}'),
                imagePath: item.imagen,
                height: 60,
                width: 60,
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
                  '${item.cantidadCarrito} x ${unitPrice.toStringAsFixed(2)} EUR',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${lineTotal.toStringAsFixed(2)} EUR',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C4432),
            ),
          ),
        ],
      ),
    );
  }

  double _parsePrice(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }
}

class _DeliverySelector extends StatelessWidget {
  final _DeliveryMethod value;
  final double subtotal;
  final ValueChanged<_DeliveryMethod> onChanged;

  const _DeliverySelector({
    required this.value,
    required this.subtotal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final standardPrice = subtotal >= 80 ? 'Gratis' : '4.99 EUR';
    return Column(
      children: [
        _DeliveryTile(
          value: _DeliveryMethod.standard,
          groupValue: value,
          title: 'Envio estandar',
          subtitle: 'Entrega 48-72h | $standardPrice',
          icon: Icons.local_shipping_outlined,
          onChanged: onChanged,
        ),
        _DeliveryTile(
          value: _DeliveryMethod.express,
          groupValue: value,
          title: 'Envio express',
          subtitle: 'Entrega 24h | 9.99 EUR',
          icon: Icons.flash_on_outlined,
          onChanged: onChanged,
        ),
        _DeliveryTile(
          value: _DeliveryMethod.pickup,
          groupValue: value,
          title: 'Recogida en tienda',
          subtitle: 'Sin coste de envio',
          icon: Icons.storefront_outlined,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final _DeliveryMethod value;
  final _DeliveryMethod groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<_DeliveryMethod> onChanged;

  const _DeliveryTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<_DeliveryMethod>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: value,
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      secondary: Icon(icon, color: const Color(0xFF2C4432)),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final _PaymentMethod value;
  final _PaymentMethod groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<_PaymentMethod> onChanged;

  const _PaymentMethodTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<_PaymentMethod>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: value,
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      secondary: Icon(icon, color: const Color(0xFF2C4432)),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _PickupInfo extends StatelessWidget {
  const _PickupInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBD4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Recogida en tienda: recibirÃ¡s una confirmacion cuando tu pedido este listo.',
        style: TextStyle(
          color: Color(0xFF2C4432),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CheckoutFooter extends StatelessWidget {
  final double subtotal;
  final double shipping;
  final double total;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  const _CheckoutFooter({
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.isSubmitting,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.18)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AmountRow(label: 'Subtotal', value: subtotal),
            const SizedBox(height: 4),
            _AmountRow(label: 'Envio', value: shipping),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${total.toStringAsFixed(2)} EUR',
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
                onPressed: isSubmitting ? null : onConfirm,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(
                  isSubmitting ? 'Procesando...' : 'Confirmar compra',
                ),
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
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;

  const _AmountRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54),
        ),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(2)} EUR',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C4432),
          ),
        ),
      ],
    );
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
              color: Color(0xFF8C3C2F),
            ),
            SizedBox(height: 10),
            Text(
              'No hay productos para checkout',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C4432),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

