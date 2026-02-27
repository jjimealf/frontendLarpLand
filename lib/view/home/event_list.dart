import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:larpland/component/event_card.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/roleplay_event.dart';
import 'package:larpland/util/error_message.dart';

class EventPage extends StatefulWidget {
  final int userId;
  final int refreshSignal;

  const EventPage({
    super.key,
    required this.userId,
    this.refreshSignal = 0,
  });

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<Timer> _notificationTimers = <Timer>[];
  final Set<int> _notifiedEventIds = <int>{};
  late Future<List<RoleplayEvent>> futureEvents;

  @override
  void initState() {
    super.initState();
    futureEvents = fetchEventList(userId: widget.userId);
    unawaited(_bootstrapNotifications());
  }

  @override
  void didUpdateWidget(covariant EventPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.refreshSignal != widget.refreshSignal) {
      _reloadEvents();
    }
  }

  @override
  void dispose() {
    for (final timer in _notificationTimers) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _bootstrapNotifications() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await initializeNotifications();
    await scheduleEventNotifications();
  }

  void _reloadEvents() {
    for (final timer in _notificationTimers) {
      timer.cancel();
    }
    _notificationTimers.clear();
    _notifiedEventIds.clear();

    setState(() {
      futureEvents = fetchEventList(userId: widget.userId);
    });
    unawaited(scheduleEventNotifications());
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // Manejar notificacion en primer plano
  }

  Future<void> onSelectNotification(String? payload) async {
    // Manejar accion de seleccion de notificacion
  }

  Future<void> scheduleEventNotifications() async {
    final events = await futureEvents;

    for (final event in events) {
      if (!event.isRegistered) {
        continue;
      }
      _scheduleNotificationForEvent(event);
    }
  }

  Future<void> scheduleNotification(RoleplayEvent event) async {
    if (_notifiedEventIds.contains(event.id)) {
      return;
    }

    await flutterLocalNotificationsPlugin.show(
      event.id,
      event.name,
      'Comienza el ${event.fechaInicio}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_channel_id',
          'Eventos',
          channelDescription: 'Notificaciones de eventos cercanos',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
    );
    _notifiedEventIds.add(event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Eventos'),
      ),
      body: FutureBuilder<List<RoleplayEvent>>(
        future: futureEvents,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final event = snapshot.data![index];
                return EventCard(
                  event: event,
                  margin: const EdgeInsets.only(bottom: 10),
                  trailingAction: ElevatedButton.icon(
                    onPressed: () => _registerInEvent(event),
                    icon: Icon(
                      event.isRegistered
                          ? Icons.verified_outlined
                          : Icons.app_registration_outlined,
                      size: 18,
                    ),
                    label: Text(
                      event.isRegistered ? 'Inscrito' : 'Inscribirse',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C4432),
                      foregroundColor: Colors.white,
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Future<void> _registerInEvent(RoleplayEvent event) async {
    if (event.isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya estas inscrito en este evento')),
      );
      return;
    }

    try {
      await registerUserInEvent(userId: widget.userId, eventId: event.id);
      if (!mounted) return;
      setState(() {
        event.isRegistered = true;
      });
      _scheduleNotificationForEvent(event);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscripcion realizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiErrorMessage(e))),
      );
    }
  }

  void _scheduleNotificationForEvent(RoleplayEvent event) {
    final now = DateTime.now();
    final eventDate = DateTime.tryParse(event.fechaInicio);
    if (eventDate == null) {
      return;
    }

    final remaining = eventDate.difference(now);
    if (remaining <= Duration.zero) {
      return;
    }

    const twentyFourHours = Duration(hours: 24);
    if (remaining <= twentyFourHours) {
      unawaited(scheduleNotification(event));
      return;
    }

    final triggerIn = remaining - twentyFourHours;
    _notificationTimers.add(
      Timer(triggerIn, () => unawaited(scheduleNotification(event))),
    );
  }
}

