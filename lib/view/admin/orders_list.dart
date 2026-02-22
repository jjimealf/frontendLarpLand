import 'package:flutter/material.dart';
import 'package:larpland/model/order.dart';
import 'package:larpland/service/order.dart';
import 'package:larpland/util/error_message.dart';

class OrdersAdminScreen extends StatefulWidget {
  const OrdersAdminScreen({super.key});

  @override
  State<OrdersAdminScreen> createState() => _OrdersAdminScreenState();
}

class _OrdersAdminScreenState extends State<OrdersAdminScreen> {
  late Future<List<UserOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchAllOrders();
  }

  Future<void> _refresh() async {
    final future = fetchAllOrders();
    setState(() {
      _ordersFuture = future;
    });
    await future;
  }

  Future<void> _changeStatus(UserOrder order, String nextStatus) async {
    if (order.status == nextStatus) return;
    try {
      await updateOrderStatus(orderId: order.id, status: nextStatus);
      if (!mounted) return;
      setState(() {
        _ordersFuture = fetchAllOrders();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido #${order.id} actualizado a $nextStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserOrder>>(
      future: _ordersFuture,
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
                  const Icon(Icons.error_outline, color: Color(0xFF1D3557), size: 40),
                  const SizedBox(height: 8),
                  Text(
                    uiErrorMessage(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data ?? const <UserOrder>[];
        if (orders.isEmpty) {
          return const _EmptyOrders();
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: orders.length,
            itemBuilder: (context, index) => _AdminOrderCard(
              order: orders[index],
              onChangeStatus: (status) => _changeStatus(orders[index], status),
            ),
          ),
        );
      },
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final UserOrder order;
  final ValueChanged<String> onChangeStatus;

  const _AdminOrderCard({
    required this.order,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            'Pedido #${order.id}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D3557),
            ),
          ),
          subtitle: Text(
            'Usuario #${order.userId} · ${_formatDate(order.createdAt)} · ${order.totalAmount.toStringAsFixed(2)} EUR',
            style: const TextStyle(fontSize: 12),
          ),
          leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF1D3557)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusBadge(status: order.status),
              PopupMenuButton<String>(
                tooltip: 'Cambiar estado',
                onSelected: onChangeStatus,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'pending', child: Text('Pendiente')),
                  PopupMenuItem(value: 'completed', child: Text('Completado')),
                  PopupMenuItem(value: 'cancelled', child: Text('Cancelado')),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          children: [
            Row(
              children: [
                _MetaChip(
                  icon: Icons.shopping_bag_outlined,
                  text: '${order.totalItems} item(s)',
                ),
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.payments_outlined,
                  text: '${order.totalAmount.toStringAsFixed(2)} EUR',
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (order.items.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sin detalle de items.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ...order.items.map((item) => _OrderItemMiniRow(item: item)),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Fecha no disponible';
    final v = value.toLocal();
    final d = v.day.toString().padLeft(2, '0');
    final m = v.month.toString().padLeft(2, '0');
    final y = v.year.toString().padLeft(4, '0');
    final hh = v.hour.toString().padLeft(2, '0');
    final mm = v.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}

class _OrderItemMiniRow extends StatelessWidget {
  final UserOrderItem item;

  const _OrderItemMiniRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D3557),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.quantity} x ${item.unitPrice} EUR',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final (label, bg, fg) = switch (normalized) {
      'completed' => ('Completado', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      'pending' => ('Pendiente', const Color(0xFFFFF8E1), const Color(0xFFF9A825)),
      'cancelled' => ('Cancelado', const Color(0xFFFFEBEE), const Color(0xFFC62828)),
      _ => (status, const Color(0xFFEAF2F8), const Color(0xFF1D3557)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1D3557)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D3557),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: Color(0xFF457B9D)),
          SizedBox(height: 8),
          Text(
            'No hay pedidos',
            style: TextStyle(
              color: Color(0xFF1D3557),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
