import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:larpland/firebase_options.dart';
import 'package:larpland/provider/cart_provider.dart';
import 'package:larpland/service/auth_session.dart';
import 'package:larpland/view/login/login.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  if (DefaultFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AuthSession.syncFromFirebase();
    firebaseReady = true;
  }

  runApp(MyApp(firebaseReady: firebaseReady));
}

class MyApp extends StatelessWidget {
  final bool firebaseReady;

  const MyApp({super.key, required this.firebaseReady});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: firebaseReady ? const LoginScreen() : const _FirebaseSetupScreen(),
      ),
    );
  }
}

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D3557), Color(0xFF457B9D), Color(0xFFA8DADC)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase no configurado',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D3557),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Completa lib/firebase_options.dart con las credenciales de tu proyecto o ejecuta flutterfire configure.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tambien agrega google-services.json (Android) y GoogleService-Info.plist (iOS) si aplica.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
