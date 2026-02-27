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
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  _DateFilter _dateFilter = _DateFilter.all;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchAllOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  const Icon(Icons.error_outline, color: Color(0xFF2C4432), size: 40),
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
        final filteredOrders = _applyFilters(orders);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: filteredOrders.isEmpty ? 2 : filteredOrders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _OrdersFiltersCard(
                  searchController: _searchController,
                  statusFilter: _statusFilter,
                  dateFilter: _dateFilter,
                  onSearchChanged: (_) => setState(() {}),
                  onClearSearch: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  onStatusChanged: (value) {
                    setState(() => _statusFilter = value);
                  },
                  onDateChanged: (value) {
                    setState(() => _dateFilter = value);
                  },
                );
              }

              if (filteredOrders.isEmpty) {
                return const _EmptyFilteredOrders();
              }

              final order = filteredOrders[index - 1];
              return _AdminOrderCard(
                order: order,
                onChangeStatus: (status) => _changeStatus(order, status),
              );
            },
          ),
        );
      },
    );
  }

  List<UserOrder> _applyFilters(List<UserOrder> orders) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return orders.where((order) {
      final matchesStatus = _statusFilter == 'all'
          ? true
          : order.status.trim().toLowerCase() == _statusFilter;

      final matchesDate = switch (_dateFilter) {
        _DateFilter.all => true,
        _DateFilter.today => _isSameDay(order.createdAt, now),
        _DateFilter.last7Days => _isWithinLastDays(order.createdAt, now, 7),
        _DateFilter.last30Days => _isWithinLastDays(order.createdAt, now, 30),
      };

      final matchesQuery = query.isEmpty
          ? true
          : _matchesSearch(order, query);

      return matchesStatus && matchesDate && matchesQuery;
    }).toList(growable: false);
  }

  bool _matchesSearch(UserOrder order, String query) {
    final normalized = query.replaceAll('#', '').trim();
    return '${order.id}'.contains(normalized) || '${order.userId}'.contains(normalized);
  }

  bool _isSameDay(DateTime? date, DateTime now) {
    if (date == null) return false;
    final local = date.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  bool _isWithinLastDays(DateTime? date, DateTime now, int days) {
    if (date == null) return false;
    final diff = now.difference(date.toLocal());
    return !diff.isNegative && diff <= Duration(days: days);
  }
}

enum _DateFilter { all, today, last7Days, last30Days }

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
      color: const Color(0xFFFFFAF0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.15)),
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
              color: Color(0xFF2C4432),
            ),
          ),
          subtitle: Text(
            'Usuario #${order.userId} - ${_formatDate(order.createdAt)} - ${order.totalAmount.toStringAsFixed(2)} EUR',
            style: const TextStyle(fontSize: 12),
          ),
          leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2C4432)),
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
                color: Color(0xFF2C4432),
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
        color: const Color(0xFFF3EBD4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2C4432)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C4432),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilteredOrders extends StatelessWidget {
  const _EmptyFilteredOrders();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Center(
        child: Text(
          'No hay pedidos con esos filtros',
          style: TextStyle(
            color: Color(0xFF2C4432),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OrdersFiltersCard extends StatelessWidget {
  final TextEditingController searchController;
  final String statusFilter;
  final _DateFilter dateFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<_DateFilter> onDateChanged;

  const _OrdersFiltersCard({
    required this.searchController,
    required this.statusFilter,
    required this.dateFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: const Color(0xFFFFFAF0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF5C3F2D).withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C4432),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por #pedido o userId...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close),
                      ),
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
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: statusFilter,
                    decoration: _dropdownDecoration('Estado'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todos')),
                      DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'completed', child: Text('Completado')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelado')),
                    ],
                    onChanged: (value) {
                      if (value != null) onStatusChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<_DateFilter>(
                    initialValue: dateFilter,
                    decoration: _dropdownDecoration('Fecha'),
                    items: const [
                      DropdownMenuItem(value: _DateFilter.all, child: Text('Todo')),
                      DropdownMenuItem(value: _DateFilter.today, child: Text('Hoy')),
                      DropdownMenuItem(
                        value: _DateFilter.last7Days,
                        child: Text('7 dias'),
                      ),
                      DropdownMenuItem(
                        value: _DateFilter.last30Days,
                        child: Text('30 dias'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onDateChanged(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
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
}

