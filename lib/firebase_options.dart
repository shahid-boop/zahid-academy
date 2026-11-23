import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// ⚠️ PLACEHOLDER OPTIONS
/// Real project ke liye ye command chalayein:
///   flutterfire configure
/// Ye file apne real apiKey / appId / projectId se overwrite ho jayegi.
/// Jab tak placeholder hai, FirebaseService.init() fail hoke app
/// automatically LOCAL DEMO mode me chal jayegi (crash nahi karegi).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'zahid-academy-placeholder',
    storageBucket: 'zahid-academy-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'zahid-academy-placeholder',
    storageBucket: 'zahid-academy-placeholder.appspot.com',
    iosBundleId: 'com.zahid.academy',
  );
}
