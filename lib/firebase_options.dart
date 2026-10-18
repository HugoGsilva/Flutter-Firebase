import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA08aL2I9Lde8CfkdNeIG0WctKzv08-sHY',
    appId: '1:605397088312:web:75b4f69fabcf847d1a8ecd',
    messagingSenderId: '605397088312',
    projectId: 'piramid-27be8',
    authDomain: 'piramid-27be8.firebaseapp.com',
    storageBucket: 'piramid-27be8.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDkxUmEAIrZeVkIJBW_XeIlZiWDp_ieRno',
    appId: '1:605397088312:android:49f08d1e4e7fbbe51a8ecd',
    messagingSenderId: '605397088312',
    projectId: 'piramid-27be8',
    storageBucket: 'piramid-27be8.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA08aL2I9Lde8CfkdNeIG0WctKzv08-sHY',
    appId: '1:605397088312:web:75b4f69fabcf847d1a8ecd',
    messagingSenderId: '605397088312',
    projectId: 'piramid-27be8',
    authDomain: 'piramid-27be8.firebaseapp.com',
    storageBucket: 'piramid-27be8.firebasestorage.app',
  );
}
