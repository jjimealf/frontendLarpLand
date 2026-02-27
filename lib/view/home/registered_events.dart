import 'package:flutter/material.dart';
import 'package:larpland/component/event_card.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/roleplay_event.dart';
import 'package:larpland/util/error_message.dart';

class RegisteredEventsScreen extends StatefulWidget {
  final int userId;

  const RegisteredEventsScreen({super.key, required this.userId});

  @override
  State<RegisteredEventsScreen> createState() => _RegisteredEventsScreenState();
}

class _RegisteredEventsScreenState extends State<RegisteredEventsScreen> {
  late Future<List<RoleplayEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = fetchRegisteredEventsForUser(widget.userId);
  }

  Future<void> _refresh() async {
    final future = fetchRegisteredEventsForUser(widget.userId);
    setState(() {
      _eventsFuture = future;
    });
    await future;
  }

  Future<void> _cancelRegistration(RoleplayEvent event) async {
    final isPast = _isPastEvent(event);
    if (isPast) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar inscripcion'),
        content: Text('Â¿Quieres cancelar tu inscripcion en "${event.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar inscripcion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await cancelUserEventRegistration(userId: widget.userId, eventId: event.id);
      if (!mounted) return;
      setState(() {
        _eventsFuture = fetchRegisteredEventsForUser(widget.userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inscripcion cancelada: ${event.name}')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis eventos'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EBD4), Color(0xFFE8DABC)],
          ),
        ),
        child: FutureBuilder<List<RoleplayEvent>>(
          future: _eventsFuture,
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

            final events = snapshot.data ?? const <RoleplayEvent>[];
            if (events.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(
                      Icons.event_busy_outlined,
                      size: 52,
                      color: Color(0xFF8C3C2F),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Todavia no te has inscrito en eventos',
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

            final upcomingEvents = events
                .where((event) => !_isPastEvent(event))
                .toList(growable: false);
            final pastEvents = events
                .where(_isPastEvent)
                .toList(growable: false);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _SectionHeader(
                    title: 'Proximos',
                    count: upcomingEvents.length,
                    icon: Icons.event_available_outlined,
                  ),
                  if (upcomingEvents.isEmpty)
                    const _SectionEmpty(message: 'No tienes eventos proximos'),
                  ...upcomingEvents.map(
                    (event) => EventCard(
                      event: event,
                      margin: const EdgeInsets.only(bottom: 10),
                      trailingAction: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: Color(0xFF2C4432),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            onPressed: () => _cancelRegistration(event),
                            icon: const Icon(Icons.event_busy_outlined, size: 18),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SectionHeader(
                    title: 'Pasados',
                    count: pastEvents.length,
                    icon: Icons.history,
                  ),
                  if (pastEvents.isEmpty)
                    const _SectionEmpty(message: 'No hay eventos pasados'),
                  ...pastEvents.map(
                    (event) => EventCard(
                      event: event,
                      margin: const EdgeInsets.only(bottom: 10),
                      trailingAction: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Color(0xFF8C3C2F),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Asistio / Finalizado',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8C3C2F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isPastEvent(RoleplayEvent event) {
    final end = DateTime.tryParse(event.fechaFin);
    final start = DateTime.tryParse(event.fechaInicio);
    final reference = end ?? start;
    if (reference == null) {
      return false;
    }
    return reference.isBefore(DateTime.now());
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2C4432)),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF2C4432),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  final String message;

  const _SectionEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5C3F2D).withValues(alpha: 0.12)),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}

