import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Firebase ko safe initialize karta hai. Config placeholder ho ya network na ho,
/// app crash nahi karta - LOCAL DEMO mode me chal jata hai.
class FirebaseService {
  FirebaseService._();

  static bool _available = false;
  static String? _error;

  static bool get isAvailable => _available;
  static String? get error => _error;

  static Future<void> init() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.startsWith('REPLACE_')) {
      _available = false;
      _error = 'Firebase not configured. Run: flutterfire configure';
      debugPrint(_error);
      return;
    }
    try {
      await Firebase.initializeApp(options: options);
      _available = true;
      _error = null;
    } catch (e) {
      _available = false;
      _error = e.toString();
      debugPrint('Firebase unavailable, using LOCAL DEMO mode: $e');
    }
  }
}
