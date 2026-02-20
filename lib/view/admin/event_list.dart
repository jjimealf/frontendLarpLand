import 'package:flutter/material.dart';
import 'package:larpland/component/event_card.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/roleplay_event.dart';
import 'package:larpland/view/admin/event_register.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Future<List<RoleplayEvent>> eventList;

  @override
  void initState() {
    super.initState();
    eventList = fetchEventList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<RoleplayEvent>>(
          future: eventList,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const _EmptyState(
                  icon: Icons.event_busy_outlined,
                  message: 'Sin eventos',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final event = snapshot.data![index];
                  return EventCard(
                    event: event,
                    margin: const EdgeInsets.only(bottom: 10),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return const _EmptyState(
                icon: Icons.error_outline,
                message: 'No se pudieron cargar eventos',
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const AddEventScreen()),
              );
              if (changed == true && mounted) {
                setState(() {
                  eventList = fetchEventList();
                });
              }
            },
            backgroundColor: const Color(0xFF1D3557),
            foregroundColor: Colors.white,
            tooltip: 'Agregar evento',
            heroTag: 'add_event',
            child: const Icon(Icons.add),
          ),
        )
      ],
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
          Icon(icon, size: 40, color: const Color(0xFF457B9D)),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF1D3557),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
