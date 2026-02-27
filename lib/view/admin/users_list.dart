import 'package:flutter/material.dart';
import 'package:larpland/model/user.dart';
import 'package:larpland/service/user.dart';

class UsersList extends StatefulWidget {
  final int? excludeUserId;

  const UsersList({super.key, this.excludeUserId});

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late Future<List<User>> futureUserList;

  @override
  void initState() {
    super.initState();
    futureUserList = fetchUserList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: futureUserList,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final users = snapshot.data!
              .where((user) => user.id != widget.excludeUserId)
              .toList(growable: false);
          if (users.isEmpty) {
            return const _EmptyState(
              icon: Icons.group_off_outlined,
              message: 'Sin usuarios',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: const Color(0xFF5C3F2D).withValues(alpha: 0.15),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2C4432),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    user.email,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.error_outline,
            message: 'No se pudieron cargar usuarios',
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF8C3C2F)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF2C4432),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

