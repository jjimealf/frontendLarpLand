import 'package:flutter/material.dart';
import 'package:larpland/service/auth_session.dart';
import 'package:larpland/view/admin/event_list.dart';
import 'package:larpland/view/admin/orders_list.dart';
import 'package:larpland/view/admin/product_list.dart';
import 'package:larpland/view/admin/users_list.dart';

class AdminHome extends StatefulWidget {
  final int userId;

  const AdminHome({super.key, required this.userId});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      UsersList(excludeUserId: widget.userId),
      ProductList(userId: widget.userId),
      const OrdersAdminScreen(),
      const EventScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF2C4432),
        foregroundColor: Colors.white,
        title: const Text(
          'LarpLand Admin',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesion',
          onPressed: () async {
            await AuthSession.signOut();
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EBD4), Color(0xFFE8DABC)],
          ),
        ),
        child: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2C4432),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (value) => setState(() => selectedIndex = value),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: const Color(0xFF2C4432),
          selectedItemColor: const Color(0xFFD3BE8A),
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Eventos',
            ),
          ],
        ),
      ),
    );
  }
}

