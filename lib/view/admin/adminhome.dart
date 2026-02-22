import 'package:flutter/material.dart';
import 'package:larpland/service/auth_session.dart';
import 'package:larpland/view/admin/event_list.dart';
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
    final isCompactTabs = MediaQuery.sizeOf(context).width < 430;
    final screens = [
      UsersList(excludeUserId: widget.userId),
      ProductList(userId: widget.userId),
      const EventScreen(),
    ];
    final tabs = <({IconData icon, String label})>[
      (icon: Icons.verified_user, label: 'Usuarios'),
      (icon: Icons.inventory_2_outlined, label: 'Inventario'),
      (icon: Icons.event, label: 'Eventos'),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D3557), Color(0xFF457B9D), Color(0xFFA8DADC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                tooltip: 'Cerrar sesion',
                                onPressed: () {
                                  AuthSession.token = null;
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.logout),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Panel de Administracion',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D3557),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Gestiona usuarios, inventario y eventos',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: List.generate(tabs.length, (index) {
                              final isSelected = selectedIndex == index;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1D3557)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () =>
                                          setState(() => selectedIndex = index),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isCompactTabs ? 4 : 8,
                                          vertical: isCompactTabs ? 8 : 12,
                                        ),
                                        child: isCompactTabs
                                            ? Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    tabs[index].icon,
                                                    size: 18,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : const Color(0xFF1D3557),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    tabs[index].label,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : const Color(0xFF1D3557),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    tabs[index].icon,
                                                    size: 18,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : const Color(0xFF1D3557),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      tabs[index].label,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : const Color(0xFF1D3557),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: IndexedStack(
                                index: selectedIndex,
                                children: screens,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
