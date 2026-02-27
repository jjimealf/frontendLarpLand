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
  static const _sectionTitles = <String>[
    'Mercado de aventureros',
    'Calendario de campanas',
    'Bitacora del heroe',
  ];

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
        toolbarHeight: 78,
        foregroundColor: const Color(0xFFF8F2DE),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1411), Color(0xFF4A2F25)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LarpLand',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Color(0xFFF8F2DE),
                letterSpacing: 0.4,
              ),
            ),
            Text(
              _sectionTitles[selectedIndex],
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFE8D5AE),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Cerrar sesion',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF8C3C2F).withValues(alpha: 0.35),
            foregroundColor: const Color(0xFFF8F2DE),
          ),
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
            colors: [Color(0xFFEFE4C8), Color(0xFFE7D9BA)],
          ),
        ),
        child: IndexedStack(
          index: selectedIndex,
          children: screen,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF251915).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFC9953E).withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0xFFC9953E).withValues(alpha: 0.24),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: selected
                      ? const Color(0xFFF8F2DE)
                      : const Color(0xFFC9B893),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                );
              }),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              height: 72,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                  if (value == 1) {
                    _eventsRefreshSignal++;
                  }
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined, color: Color(0xFFC9B893)),
                  selectedIcon: Icon(Icons.inventory_2, color: Color(0xFFF8F2DE)),
                  label: 'Productos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note_outlined, color: Color(0xFFC9B893)),
                  selectedIcon: Icon(Icons.event_note, color: Color(0xFFF8F2DE)),
                  label: 'Eventos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded, color: Color(0xFFC9B893)),
                  selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFF8F2DE)),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
