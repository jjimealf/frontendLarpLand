import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:larpland/service/firebase_backend.dart';

class AuthSession {
  static String? token;
  static String? firebaseUid;
  static int? userId;
  static int? rol;

  static void bind({
    String? idToken,
    String? uid,
    int? sessionUserId,
    int? sessionRol,
  }) {
    token = idToken;
    firebaseUid = uid;
    userId = sessionUserId;
    rol = sessionRol;
  }

  static Future<void> syncFromFirebase() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      clearLocal();
      return;
    }

    final profile = await FirebaseBackend.ensureUserProfile(firebaseUser: user);
    bind(
      idToken: await user.getIdToken(),
      uid: user.uid,
      sessionUserId: profile['id'] is int
          ? profile['id'] as int
          : int.tryParse('${profile['id'] ?? ''}'),
      sessionRol: profile['rol'] is int
          ? profile['rol'] as int
          : int.tryParse('${profile['rol'] ?? ''}'),
    );
  }

  static Future<void> signOut() async {
    try {
      await FirebaseBackend.auth.signOut();
    } finally {
      clearLocal();
    }
  }

  static void clearLocal() {
    token = null;
    firebaseUid = null;
    userId = null;
    rol = null;
  }
}
