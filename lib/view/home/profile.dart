import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:larpland/model/order.dart';
import 'package:larpland/model/user.dart';
import 'package:larpland/service/auth_session.dart';
import 'package:larpland/service/order.dart';
import 'package:larpland/service/roleplay_event.dart';
import 'package:larpland/service/user.dart';
import 'package:larpland/view/home/orders_history.dart';
import 'package:larpland/view/home/registered_events.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<_ProfileData> _futureProfile;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final user = await showUser(widget.userId);
    final registeredEventIds = await fetchRegisteredEventIds(widget.userId);
    final orders = await fetchUserOrders(widget.userId);
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    return _ProfileData(
      user: user,
      registeredEventsCount: registeredEventIds.length,
      orders: orders,
      firebaseEmailVerified: firebaseUser?.emailVerified ?? false,
      firebaseUid: firebaseUser?.uid,
    );
  }

  Future<void> _refresh() async {
    final future = _loadProfile();
    setState(() {
      _futureProfile = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FBFF), Color(0xFFEFF4FA)],
        ),
      ),
      child: FutureBuilder<_ProfileData>(
        future: _futureProfile,
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
                      color: Color(0xFF1D3557),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Sin datos de perfil'));
          }
          final isAdmin = (AuthSession.rol ?? 0) == 1;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _ProfileHeaderCard(user: data.user),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileDialog(data.user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar perfil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D3557),
                    side: const BorderSide(color: Color(0xFF1D3557)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Cuenta',
                  children: [
                    _InfoRow(
                      icon: Icons.alternate_email,
                      label: 'Correo',
                      value: data.user.email,
                    ),
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Verificacion',
                      value: data.firebaseEmailVerified ? 'Verificado' : 'Pendiente',
                    ),
                    if (isAdmin)
                      const _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Rol',
                        value: 'Administrador',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Actividad',
                  children: [
                    _InfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Eventos inscritos',
                      value: '${data.registeredEventsCount}',
                    ),
                    _InfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Pedidos realizados',
                      value: '${data.orders.length}',
                    ),
                    if (isAdmin)
                      _InfoRow(
                        icon: Icons.numbers_outlined,
                        label: 'ID de usuario',
                        value: '${data.user.id}',
                      ),
                    if (isAdmin)
                      _InfoRow(
                        icon: Icons.fingerprint,
                        label: 'Firebase UID',
                        value: data.firebaseUid ?? 'No disponible',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RegisteredEventsScreen(userId: widget.userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Ver mis eventos inscritos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF457B9D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrdersHistoryScreen(userId: widget.userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Ver mis pedidos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D3557),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Pedidos recientes',
                  children: data.orders.isEmpty
                      ? const [
                          Text(
                            'Todavia no has realizado pedidos.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ]
                      : data.orders
                          .take(5)
                          .map((order) => _OrderRow(order: order))
                          .toList(growable: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditProfileDialog(User user) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    var isSaving = false;

    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: !isSaving,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                if (isSaving) return;
                if (!formKey.currentState!.validate()) return;
                setDialogState(() {
                  isSaving = true;
                });
                try {
                  await updateCurrentUserProfile(
                    userId: widget.userId,
                    name: nameController.text,
                    email: emailController.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                  setDialogState(() {
                    isSaving = false;
                  });
                }
              }

              return AlertDialog(
                title: const Text('Editar perfil'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!raw.contains('@') || !raw.contains('.')) {
                            return 'Correo no valido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving ? null : submit,
                    icon: isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (saved == true) {
        await _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } finally {
      nameController.dispose();
      emailController.dispose();
    }
  }
}

class _ProfileData {
  final User user;
  final int registeredEventsCount;
  final List<UserOrder> orders;
  final bool firebaseEmailVerified;
  final String? firebaseUid;

  const _ProfileData({
    required this.user,
    required this.registeredEventsCount,
    required this.orders,
    required this.firebaseEmailVerified,
    required this.firebaseUid,
  });
}

class _ProfileHeaderCard extends StatelessWidget {
  final User user;

  const _ProfileHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final trimmed = user.name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1D3557),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D3557),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D3557),
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1D3557)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D3557),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final UserOrder order;

  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(order.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: Color(0xFF1D3557),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D3557),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$date · ${order.totalItems} item(s) · ${order.totalAmount.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            _OrderStatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Fecha no disponible';
    }
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final (label, bg, fg) = switch (normalized) {
      'completed' => ('Completado', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      'pending' => ('Pendiente', const Color(0xFFFFF8E1), const Color(0xFFF9A825)),
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
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
