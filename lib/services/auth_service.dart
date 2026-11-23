import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'firebase_service.dart';

class AuthService {
  AuthService._();

  static bool get available => FirebaseService.isAvailable;

  static Stream<AppUser?> get authChanges {
    if (!available) return Stream<AppUser?>.value(null);
    return FirebaseAuth.instance.authStateChanges().asyncMap(_mapUser);
  }

  static AppUser? get currentUser {
    if (!available) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email ?? 'User',
    );
  }

  static Future<AppUser?> _mapUser(User? user) async {
    if (user == null) return null;
    var role = 'user';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      role = doc.data()?['role']?.toString() ?? 'user';
    } catch (_) {
      // role default 'user'
    }
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email ?? 'User',
      role: role,
    );
  }

  static Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _ensureAvailable();
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(displayName.trim());
    final user = AppUser(
      uid: cred.user!.uid,
      email: cred.user!.email ?? email.trim(),
      displayName: displayName.trim(),
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(user.toMap());
    return user;
  }

  static Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final mapped = await _mapUser(cred.user);
    return mapped ??
        AppUser(uid: cred.user!.uid, email: email.trim(), displayName: email.trim());
  }

  static Future<void> signOut() async {
    if (!available) return;
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> updateDisplayName(String name) async {
    _ensureAvailable();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'displayName': name.trim()});
  }

  /// Admin role sirf already-admin hi de sakta hai (admin panel se call).
  static Future<void> setRole({
    required String adminUid,
    required String targetUid,
    required String role,
  }) async {
    _ensureAvailable();
    final adminDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(adminUid)
        .get();
    if (adminDoc.data()?['role'] != 'admin') {
      throw Exception('Only admins can change roles.');
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .update({'role': role});
  }

  static void _ensureAvailable() {
    if (!available) {
      throw Exception(
        'Firebase configured nahi hai. Pehle "flutterfire configure" chalayein '
        'aur google-services.json add karein.',
      );
    }
  }
}
