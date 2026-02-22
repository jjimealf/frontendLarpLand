import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseBackend {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static fb_auth.FirebaseAuth get auth => fb_auth.FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> get products =>
      firestore.collection('products');

  static CollectionReference<Map<String, dynamic>> get events =>
      firestore.collection('events');

  static CollectionReference<Map<String, dynamic>> get reviews =>
      firestore.collection('reviews');

  static DocumentReference<Map<String, dynamic>> get _counterDoc =>
      firestore.collection('_meta').doc('counters');

  static void ensureInitialized() {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase no esta inicializado. Configura firebase_options.dart y llama a Firebase.initializeApp() en main().',
      );
    }
  }

  static Future<int> nextNumericId(String counterKey) async {
    ensureInitialized();
    return firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_counterDoc);
      final data = snapshot.data() ?? const <String, dynamic>{};
      final current = _asInt(data[counterKey]) ?? 0;
      final next = current + 1;
      transaction.set(_counterDoc, <String, dynamic>{
        counterKey: next,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return next;
    });
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> findByNumericId(
    CollectionReference<Map<String, dynamic>> collection,
    int id,
  ) async {
    ensureInitialized();
    final query = await collection.where('id', isEqualTo: id).limit(1).get();
    if (query.docs.isEmpty) {
      throw StateError('No se encontro el registro con id=$id');
    }
    return query.docs.first;
  }

  static Future<DocumentReference<Map<String, dynamic>>> findRefByNumericId(
    CollectionReference<Map<String, dynamic>> collection,
    int id,
  ) async {
    final doc = await findByNumericId(collection, id);
    return doc.reference;
  }

  static Future<Map<String, dynamic>> ensureUserProfile({
    required fb_auth.User firebaseUser,
    String? fallbackName,
  }) async {
    ensureInitialized();
    try {
      final existing = await users
          .where('firebase_uid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        final ref = existing.docs.first.reference;
        final current = existing.docs.first.data();
        final merged = <String, dynamic>{
          ...current,
          'email': firebaseUser.email ?? current['email'] ?? '',
          if ((firebaseUser.displayName ?? '').trim().isNotEmpty)
            'name': firebaseUser.displayName!.trim()
          else if ((fallbackName ?? '').trim().isNotEmpty)
            'name': fallbackName!.trim(),
          'firebase_uid': firebaseUser.uid,
          'updated_at': FieldValue.serverTimestamp(),
        };
        await ref.set(merged, SetOptions(merge: true));
        return normalizeMap(merged);
      }

      final userId = await nextNumericId('users');
      final name = (firebaseUser.displayName ?? fallbackName ?? '').trim();
      final payload = <String, dynamic>{
        'id': userId,
        'name': name.isEmpty ? 'Usuario' : name,
        'email': firebaseUser.email ?? '',
        'rol': 0,
        'firebase_uid': firebaseUser.uid,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      await users.doc(firebaseUser.uid).set(payload, SetOptions(merge: true));
      return normalizeMap(payload);
    } on FirebaseException catch (e) {
      throw Exception(_firestoreErrorMessage(e));
    }
  }

  static Map<String, dynamic> normalizeSnapshotData(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return normalizeMap(<String, dynamic>{...data, 'doc_id': doc.id});
  }

  static Map<String, dynamic> normalizeMap(Map<String, dynamic> source) {
    return source.map((key, value) => MapEntry(key, _normalizeValue(value)));
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is Map<String, dynamic>) {
      return normalizeMap(value);
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    return value;
  }

  static int? _asInt(dynamic value) {
    return switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };
  }

  static String _firestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firestore denego permisos. Revisa las reglas de Firestore/Storage.';
      case 'failed-precondition':
        return 'Firestore no esta listo en el proyecto (crea la base de datos en Firebase Console).';
      case 'unavailable':
        return 'Firestore no disponible. Verifica conexion a internet y estado del proyecto.';
      case 'unauthenticated':
        return 'Sesion no autenticada para acceder a Firestore.';
      case 'unknown':
        return 'Error de Firestore (unknown). Normalmente indica reglas incorrectas o Firestore sin inicializar en Firebase Console.';
      default:
        return e.message == null || e.message!.trim().isEmpty
            ? 'Error de Firestore (${e.code}).'
            : 'Error de Firestore (${e.code}): ${e.message}';
    }
  }
}
