import 'package:flutter/material.dart';
import 'package:larpland/component/smart_network_image.dart';
import 'package:larpland/model/order.dart';
import 'package:larpland/service/order.dart';
import 'package:larpland/util/error_message.dart';

class OrdersHistoryScreen extends StatefulWidget {
  final int userId;

  const OrdersHistoryScreen({super.key, required this.userId});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  late Future<List<UserOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchUserOrders(widget.userId);
  }

  Future<void> _refresh() async {
    final future = fetchUserOrders(widget.userId);
    setState(() {
      _ordersFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EBD4), Color(0xFFE8DABC)],
          ),
        ),
        child: FutureBuilder<List<UserOrder>>(
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
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                        color: Color(0xFF2C4432),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        uiErrorMessage(snapshot.error!),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
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
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 52,
                      color: Color(0xFF8C3C2F),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Todavia no tienes pedidos',
                        style: TextStyle(
                          color: Color(0xFF2C4432),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: orders.length,
                itemBuilder: (context, index) => _OrderCard(order: orders[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final UserOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(order.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFF2C4432),
          ),
          title: Text(
            'Pedido #${order.id}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C4432),
            ),
          ),
          subtitle: Text(
            '$date | ${order.totalItems} item(s) | ${order.totalAmount.toStringAsFixed(2)} EUR',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: _OrderStatusBadge(status: order.status),
          children: [
            if (order.items.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sin detalle de productos.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ...order.items.map((item) => _OrderItemRow(item: item)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Fecha no disponible';
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}

class _OrderItemRow extends StatelessWidget {
  final UserOrderItem item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 52,
              height: 52,
              color: const Color(0xFFF3EBD4),
              child: item.imageUrl.trim().isEmpty
                  ? const Icon(Icons.image_not_supported_outlined)
                  : SmartNetworkImage(
                      imagePath: item.imageUrl,
                      height: 52,
                      width: 52,
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
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C4432),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} x ${item.unitPrice} EUR',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.lineTotal.toStringAsFixed(2)} EUR',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C4432),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final (label, bg, fg) = switch (normalized) {
      'completed' => (
          'Completado',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
        ),
      'pending' => (
          'Pendiente',
          const Color(0xFFFFF8E1),
          const Color(0xFFF9A825),
        ),
      _ => (status, const Color(0xFFF3EBD4), const Color(0xFF2C4432)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

