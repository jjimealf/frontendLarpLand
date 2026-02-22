import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static const String _placeholder = 'REPLACE_WITH_FIREBASE_CONFIG';

  static bool get isConfigured {
    final options = currentPlatform;
    return options.apiKey.isNotEmpty &&
        options.apiKey != _placeholder &&
        options.appId.isNotEmpty &&
        options.appId != _placeholder &&
        options.projectId.isNotEmpty &&
        options.projectId != _placeholder &&
        options.messagingSenderId.isNotEmpty &&
        options.messagingSenderId != _placeholder;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no soporta esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBg2JPMozYcaVISOu3pDffsiI8z71SHPyo',
    appId: '1:739095155067:web:490fa2e2b8a267f85b6dde',
    messagingSenderId: '739095155067',
    projectId: 'larpland-61c86',
    authDomain: 'larpland-61c86.firebaseapp.com',
    storageBucket: 'larpland-61c86.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDpTruCnvZ4YqD_CMITqAeQSkWIvh6dOiU',
    appId: '1:551562159252:android:f882bc8173a889a3af4081',
    messagingSenderId: '551562159252',
    projectId: 'larpland-c6689',
    storageBucket: 'larpland-c6689.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDKLgGTSRXIpl2HasZSJqPb0KYsV-JR26s',
    appId: '1:739095155067:ios:f4eaf9fcb8f1182c5b6dde',
    messagingSenderId: '739095155067',
    projectId: 'larpland-61c86',
    storageBucket: 'larpland-61c86.firebasestorage.app',
    iosBundleId: 'com.example.larpland',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDKLgGTSRXIpl2HasZSJqPb0KYsV-JR26s',
    appId: '1:739095155067:ios:f4eaf9fcb8f1182c5b6dde',
    messagingSenderId: '739095155067',
    projectId: 'larpland-61c86',
    storageBucket: 'larpland-61c86.firebasestorage.app',
    iosBundleId: 'com.example.larpland',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBg2JPMozYcaVISOu3pDffsiI8z71SHPyo',
    appId: '1:739095155067:web:08a4ae828ce965c75b6dde',
    messagingSenderId: '739095155067',
    projectId: 'larpland-61c86',
    authDomain: 'larpland-61c86.firebaseapp.com',
    storageBucket: 'larpland-61c86.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    storageBucket: _placeholder,
  );
}