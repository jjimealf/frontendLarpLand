import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:larpland/model/roleplay_event.dart';
import 'package:larpland/service/firebase_backend.dart';

Future<List<RoleplayEvent>> fetchEventList() async {
  FirebaseBackend.ensureInitialized();
  final snapshot = await FirebaseBackend.events.orderBy('id').get();
  return snapshot.docs
      .map(FirebaseBackend.normalizeSnapshotData)
      .map(RoleplayEvent.fromJson)
      .toList(growable: false);
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
}
