import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:larpland/model/user.dart';
import 'package:larpland/service/firebase_backend.dart';

Future<User> register(String name, String email, String password) async {
  FirebaseBackend.ensureInitialized();

  try {
    final credential = await FirebaseBackend.auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final createdUser = credential.user;
    if (createdUser == null) {
      throw Exception('No se pudo crear el usuario en Firebase Auth.');
    }

    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      await createdUser.updateDisplayName(trimmedName);
    }

    final profile = await FirebaseBackend.ensureUserProfile(
      firebaseUser: createdUser,
      fallbackName: trimmedName,
    );
    await FirebaseBackend.auth.signOut();
    return User.fromJson(profile);
  } on fb_auth.FirebaseAuthException catch (e) {
    throw Exception(_firebaseAuthMessage(e));
  }
}

String _firebaseAuthMessage(fb_auth.FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'El correo ya esta registrado.';
    case 'invalid-email':
      return 'El correo electronico no es valido.';
    case 'weak-password':
      return 'La contrasena es demasiado debil.';
    case 'network-request-failed':
      return 'Sin conexion a internet.';
    default:
      return e.message ?? 'No se pudo completar el registro.';
  }
}
