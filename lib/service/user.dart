import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:larpland/model/user.dart';
import 'package:larpland/service/app_error.dart';
import 'package:larpland/service/auth_session.dart';
import 'package:larpland/service/firebase_backend.dart';

Future<List<User>> fetchUserList() async {
  FirebaseBackend.ensureInitialized();
  final snapshot = await FirebaseBackend.users.orderBy('id').get();
  return snapshot.docs
      .map(FirebaseBackend.normalizeSnapshotData)
      .map(User.fromJson)
      .toList(growable: false);
}

Future<User> showUser(int id) async {
  FirebaseBackend.ensureInitialized();
  final doc = await FirebaseBackend.findByNumericId(FirebaseBackend.users, id);
  return User.fromJson(FirebaseBackend.normalizeSnapshotData(doc));
}

Future<User> updateCurrentUserProfile({
  required int userId,
  required String name,
  required String email,
}) async {
  FirebaseBackend.ensureInitialized();

  final trimmedName = name.trim();
  final trimmedEmail = email.trim();
  if (trimmedName.isEmpty) {
    throw const AppError(
      code: 'validation.empty_name',
      message: 'El nombre no puede estar vacio.',
    );
  }
  if (trimmedEmail.isEmpty) {
    throw const AppError(
      code: 'validation.empty_email',
      message: 'El correo no puede estar vacio.',
    );
  }

  final firebaseUser = FirebaseBackend.auth.currentUser;
  if (firebaseUser == null) {
    throw const AppError(
      code: 'auth.no_active_session',
      message: 'No hay una sesion activa.',
    );
  }

  try {
    if ((firebaseUser.displayName ?? '') != trimmedName) {
      await firebaseUser.updateDisplayName(trimmedName);
    }
    if ((firebaseUser.email ?? '') != trimmedEmail) {
      // ignore: deprecated_member_use
      await firebaseUser.updateEmail(trimmedEmail);
    }
    await firebaseUser.reload();
  } on fb_auth.FirebaseAuthException catch (e) {
    throw AppError(
      code: 'auth.${e.code}',
      message: _firebaseAuthMessage(e),
      cause: e,
    );
  }

  try {
    final ref = await FirebaseBackend.findRefByNumericId(FirebaseBackend.users, userId);
    await ref.set(<String, dynamic>{
      'name': trimmedName,
      'email': trimmedEmail,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } on FirebaseException catch (e) {
    throw AppError(
      code: 'firestore.${e.code}',
      message: e.message == null || e.message!.trim().isEmpty
          ? 'No se pudo actualizar el perfil en Firestore (${e.code}).'
          : 'No se pudo actualizar el perfil en Firestore: ${e.message}',
      cause: e,
    );
  }

  await AuthSession.syncFromFirebase();
  return showUser(userId);
}

String _firebaseAuthMessage(fb_auth.FirebaseAuthException e) {
  switch (e.code) {
    case 'requires-recent-login':
      return 'Para cambiar el correo debes volver a iniciar sesion.';
    case 'email-already-in-use':
      return 'Ese correo ya esta en uso.';
    case 'invalid-email':
      return 'El correo electronico no es valido.';
    case 'network-request-failed':
      return 'Sin conexion a internet.';
    default:
      return e.message ?? 'No se pudo actualizar la cuenta.';
  }
}
