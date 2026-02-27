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

  Future<void> _openEventForm({RoleplayEvent? event}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEventScreen(event: event)),
    );
    if (changed == true && mounted) {
      setState(() {
        eventList = fetchEventList();
      });
    }
  }

  Future<void> _deleteEvent(RoleplayEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar evento'),
        content: Text('Â¿Seguro que quieres borrar "${event.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await deleteEvent(event.id);
      if (!mounted) {
        return;
      }
      setState(() {
        eventList = fetchEventList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento borrado correctamente')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el evento: $e')),
      );
    }
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
                    trailingAction: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openEventForm(event: event),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _deleteEvent(event),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Borrar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
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
            onPressed: _openEventForm,
            backgroundColor: const Color(0xFF2C4432),
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

