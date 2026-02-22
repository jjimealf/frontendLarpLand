import 'package:flutter/material.dart';
import 'package:larpland/service/auth_session.dart';
import 'package:larpland/view/home/catalog.dart';
import 'package:larpland/view/home/event_list.dart';
import 'package:larpland/view/home/profile.dart';

class HomeScreen extends StatefulWidget {

  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  int _eventsRefreshSignal = 0;

  @override
  Widget build(BuildContext context) {
    final screen = [
      CatalogScreen(userId: widget.userId),
      EventPage(
        userId: widget.userId,
        refreshSignal: _eventsRefreshSignal,
      ),
      UserProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1D3557),
        foregroundColor: Colors.white,
        title: const Text(
          'LarpLand',
          style: TextStyle(fontWeight: FontWeight.w700),
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
      body: IndexedStack(
        index: selectedIndex,
        children: screen,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1D3557),
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
          onTap: (value) {
            setState(() {
              selectedIndex = value;
              if (value == 1) {
                _eventsRefreshSignal++;
              }
            });
          },
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: const Color(0xFF1D3557),
          selectedItemColor: const Color(0xFFA8DADC),
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Productos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Eventos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
