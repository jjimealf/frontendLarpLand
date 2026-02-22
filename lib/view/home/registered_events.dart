import 'package:flutter/material.dart';
import 'package:larpland/component/event_card.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/roleplay_event.dart';

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
            colors: [Color(0xFFF8FBFF), Color(0xFFEFF4FA)],
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
                        color: Color(0xFF1D3557),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${snapshot.error}',
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
                      color: Color(0xFF457B9D),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Todavia no te has inscrito en eventos',
                        style: TextStyle(
                          color: Color(0xFF1D3557),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(
                    event: event,
                    margin: const EdgeInsets.only(bottom: 10),
                    trailingAction: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: Color(0xFF1D3557),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Inscrito',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D3557),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
