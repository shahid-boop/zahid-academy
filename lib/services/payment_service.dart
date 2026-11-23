import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/payment_request.dart';
import 'firebase_service.dart';

/// Payment requests + screenshot upload + admin verification.
/// IMPORTANT: sirf approved status paid access deta hai (AppState isi ko follow karta hai).
class PaymentService {
  PaymentService._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('payments');

  static Future<PaymentRequest> submit({
    required AppUser user,
    required String method,
    required String accountNumber,
    required String reference,
    XFile? screenshot,
    String? note,
  }) async {
    if (!FirebaseService.isAvailable) {
      throw Exception('Payment request ke liye Firebase configured hona zaroori hai.');
    }
    if (reference.trim().isEmpty) {
      throw Exception('Payment reference zaroori hai.');
    }

    String? screenshotUrl;
    if (screenshot != null) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('payment-screenshots/${user.uid}/$stamp.jpg');
      await ref.putFile(File(screenshot.path));
      screenshotUrl = await ref.getDownloadURL();
    }

    final request = PaymentRequest(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, 6)}',
      userId: user.uid,
      userEmail: user.email,
      method: method,
      accountNumber: accountNumber.trim(),
      reference: reference.trim(),
      screenshotUrl: screenshotUrl,
      note: note?.trim(),
      status: PaymentStatus.pending,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    await _col.doc(request.id).set(request.toMap());
    return request;
  }

  static Stream<List<PaymentRequest>> watchMyRequests(String uid) {
    if (!FirebaseService.isAvailable) {
      return Stream<List<PaymentRequest>>.value(const <PaymentRequest>[]);
    }
    return _stream(_col.where('userId', isEqualTo: uid));
  }

  static Stream<List<PaymentRequest>> watchAllRequests() {
    if (!FirebaseService.isAvailable) {
      return Stream<List<PaymentRequest>>.value(const <PaymentRequest>[]);
    }
    return _stream(_col.orderBy('createdAtMs', descending: true));
  }

  static Stream<List<PaymentRequest>> _stream(
    Query<Map<String, dynamic>> query,
  ) {
    late final StreamController<List<PaymentRequest>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
    controller = StreamController<List<PaymentRequest>>(
      onCancel: () => sub?.cancel(),
    );
    sub = query.snapshots().listen(
      (snap) {
        if (controller.isClosed) return;
        controller.add(snap.docs
            .map((doc) => PaymentRequest.fromMap(doc.id, doc.data()))
            .toList());
      },
      onError: (_) {
        if (!controller.isClosed) {
          controller.add(const <PaymentRequest>[]);
        }
      },
    );
    return controller.stream;
  }

  /// Admin verification. Client-side role check + Firestore role check.
  /// Production me isko Cloud Function / Admin SDK me daalna chahiye.
  static Future<void> review({
    required AppUser admin,
    required String requestId,
    required PaymentStatus status,
  }) async {
    if (!admin.isAdmin) {
      throw Exception('Sirf admin payment verify kar sakta hai.');
    }
    final adminDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(admin.uid)
        .get();
    if (adminDoc.data()?['role'] != 'admin') {
      throw Exception('Admin permission denied.');
    }

    await _col.doc(requestId).update({
      'status': status.name,
      'reviewedAtMs': DateTime.now().millisecondsSinceEpoch,
      'reviewerId': admin.uid,
    });
  }
}
