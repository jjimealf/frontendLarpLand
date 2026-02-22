import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/firebase_backend.dart';

Future<List<RoleplayEvent>> fetchEventList({int? userId}) async {
  FirebaseBackend.ensureInitialized();
  final registeredEventIds = userId == null
      ? const <int>{}
      : await fetchRegisteredEventIds(userId);

  final events = (await FirebaseBackend.events.orderBy('id').get()).docs
      .map(FirebaseBackend.normalizeSnapshotData)
      .map(RoleplayEvent.fromJson)
      .toList(growable: false);

  if (registeredEventIds.isEmpty) {
    return events;
  }

  for (final event in events) {
    event.isRegistered = registeredEventIds.contains(event.id);
  }
  return events;
}

Future<RoleplayEvent> addEvent(
  String name,
  String description,
  String fechaInicio,
  String fechaFin,
) async {
  FirebaseBackend.ensureInitialized();
  final id = await FirebaseBackend.nextNumericId('events');
  final data = <String, dynamic>{
    'id': id,
    'nombre': name,
    'descripcion': description,
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
  await FirebaseBackend.events.add(data);
  return RoleplayEvent.fromJson(data);
}

Future<void> updateEvent(
  int id, {
  required String name,
  required String description,
  required String fechaInicio,
  required String fechaFin,
}) async {
  FirebaseBackend.ensureInitialized();
  final ref = await FirebaseBackend.findRefByNumericId(FirebaseBackend.events, id);
  await ref.set(<String, dynamic>{
    'nombre': name,
    'descripcion': description,
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  }, SetOptions(merge: true));
}

Future<void> deleteEvent(int id) async {
  FirebaseBackend.ensureInitialized();
  final ref = await FirebaseBackend.findRefByNumericId(FirebaseBackend.events, id);
  await ref.delete();

  final registrations = await _eventRegistrations
      .where('event_id', isEqualTo: id)
      .get();
  for (final doc in registrations.docs) {
    await doc.reference.delete();
  }
}

Future<Set<int>> fetchRegisteredEventIds(int userId) async {
  FirebaseBackend.ensureInitialized();
  final snapshot =
      await _eventRegistrations.where('user_id', isEqualTo: userId).get();
  return snapshot.docs
      .map((doc) => doc.data()['event_id'])
      .map(_asInt)
      .whereType<int>()
      .toSet();
}

Future<void> registerUserInEvent({
  required int userId,
  required int eventId,
}) async {
  FirebaseBackend.ensureInitialized();
  final docId = '${userId}_$eventId';
  await _eventRegistrations.doc(docId).set(<String, dynamic>{
    'id': docId,
    'user_id': userId,
    'event_id': eventId,
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

CollectionReference<Map<String, dynamic>> get _eventRegistrations =>
    FirebaseBackend.firestore.collection('event_registrations');

int? _asInt(dynamic value) {
  return switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v),
    _ => null,
  };
}
