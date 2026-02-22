import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:larpland/model/login.dart';
import 'package:larpland/service/auth_session.dart';
import 'package:larpland/service/firebase_backend.dart';

Future<Login> login(String email, String password) async {
  FirebaseBackend.ensureInitialized();

  try {
    final credential = await FirebaseBackend.auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw fb_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se pudo recuperar el usuario autenticado.',
      );
    }

    final profile = await FirebaseBackend.ensureUserProfile(firebaseUser: user);
    final rol = _asInt(profile['rol']) ?? 0;
    final userId = _asInt(profile['id']);
    if (userId == null) {
      throw Exception('El perfil del usuario no contiene un id numerico.');
    }

    final idToken = await user.getIdToken();
    final result = Login(
      status: 'success',
      rol: rol,
      message: 'Login exitoso',
      userId: userId,
      token: idToken,
    );

    AuthSession.bind(
      idToken: idToken,
      uid: user.uid,
      sessionUserId: userId,
      sessionRol: rol,
    );
    return result;
  } on fb_auth.FirebaseAuthException catch (e) {
    throw Exception(_firebaseAuthMessage(e));
  }
}

int? _asInt(dynamic value) {
  return switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v),
    _ => null,
  };
}

String _firebaseAuthMessage(fb_auth.FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Correo o contrasena incorrectos.';
    case 'invalid-email':
      return 'El correo electronico no es valido.';
    case 'too-many-requests':
      return 'Demasiados intentos. Intenta de nuevo mas tarde.';
    case 'network-request-failed':
      return 'Sin conexion a internet.';
    default:
      return e.message ?? 'No se pudo iniciar sesion.';
  }
}
