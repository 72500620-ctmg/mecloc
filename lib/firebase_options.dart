import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opções padrão do Firebase geradas para o projeto MecLoc.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC99yftRUVOv2AYVc3L7HEWQDzFh6Hxq7I',
    appId: '1:823400139263:web:fa30de6f514b6f1690bfca',
    messagingSenderId: '823400139263',
    projectId: 'mecloc',
    authDomain: 'mecloc.firebaseapp.com',
    storageBucket: 'mecloc.firebasestorage.app',
    measurementId: 'G-K9MEZ63XVQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC99yftRUVOv2AYVc3L7HEWQDzFh6Hxq7I',
    appId: '1:823400139263:web:fa30de6f514b6f1690bfca',
    messagingSenderId: '823400139263',
    projectId: 'mecloc',
    storageBucket: 'mecloc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC99yftRUVOv2AYVc3L7HEWQDzFh6Hxq7I',
    appId: '1:823400139263:web:fa30de6f514b6f1690bfca',
    messagingSenderId: '823400139263',
    projectId: 'mecloc',
    storageBucket: 'mecloc.firebasestorage.app',
  );
}

