import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/app_data.dart';
import '../models/app_file.dart';
import 'firebase_service.dart';

/// Firestore se content stream karta hai. Firebase na ho to local data deta hai.
class ContentRepository {
  ContentRepository._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('contents');

  static Stream<List<AppFile>> watchAll() {
    // Firebase available na ho to _col ko touch bhi mat karo (throw karega).
    if (!FirebaseService.isAvailable) {
      return Stream<List<AppFile>>.value(AppData.allFiles);
    }
    return _stream(_col.where('published', isEqualTo: true), AppData.allFiles);
  }

  static Stream<List<AppFile>> watchByCategory(String category) {
    final local = AppData.allFiles.where((f) => f.category == category).toList();
    if (!FirebaseService.isAvailable) {
      return Stream<List<AppFile>>.value(local);
    }
    return _stream(
      _col.where('category', isEqualTo: category).where('published', isEqualTo: true),
      local,
    );
  }

  static Stream<List<AppFile>> watchRecent({int limit = 3}) {
    return watchAll().map((items) {
      if (items.isEmpty) return AppData.recentLessons.take(limit).toList();
      final sorted = List<AppFile>.from(items)
        ..sort((a, b) => (b.publishedAtMs ?? 0).compareTo(a.publishedAtMs ?? 0));
      return sorted.take(limit).toList();
    });
  }

  static Stream<List<AppFile>> _stream(
    Query<Map<String, dynamic>> query,
    List<AppFile> local,
  ) {
    if (!FirebaseService.isAvailable) return Stream<List<AppFile>>.value(local);

    late final StreamController<List<AppFile>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
    controller = StreamController<List<AppFile>>(
      onCancel: () => sub?.cancel(),
    );

    sub = query.snapshots().listen(
      (snap) {
        if (controller.isClosed) return;
        final remote = snap.docs
            .map((doc) => AppFile.fromMap(doc.id, doc.data()))
            .toList();
        controller.add(remote.isEmpty ? local : _merge(local, remote));
      },
      onError: (_) {
        if (!controller.isClosed) controller.add(local);
      },
    );

    return controller.stream;
  }

  static List<AppFile> _merge(List<AppFile> local, List<AppFile> remote) {
    final byId = <String, AppFile>{for (final f in local) f.id: f};
    for (final item in remote) {
      byId[item.id] = item;
    }
    return byId.values.toList();
  }

  static List<AppFile> search(List<AppFile> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (f) =>
              f.name.toLowerCase().contains(q) ||
              f.category.toLowerCase().contains(q) ||
              f.typeLabel.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Admin upload: Storage me file + Firestore me unpublished content.
  static Future<AppFile> uploadContent({
    required String filePath,
    required String fileName,
    required String name,
    required String category,
    required FileKind kind,
    required bool isPremium,
  }) async {
    if (!FirebaseService.isAvailable) {
      throw Exception('Upload ke liye Firebase configured hona zaroori hai.');
    }

    final file = File(filePath);
    final sizeKb = (await file.length()) / 1024;
    final sizeLabel = sizeKb >= 1024
        ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
        : '${sizeKb.toStringAsFixed(0)} KB';

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ref = FirebaseStorage.instance
        .ref()
        .child('contents/$stamp-$safeName');
    final snapshot = await ref.putFile(file);
    final url = await snapshot.ref.getDownloadURL();

    final item = AppFile(
      id: 'up_${stamp}_${safeName.hashCode.abs()}',
      name: name.trim().isEmpty ? fileName : name.trim(),
      category: category,
      kind: kind,
      url: url,
      sizeLabel: sizeLabel,
      publishedAtMs: stamp,
      isPremium: isPremium,
      published: false,
    );

    await _col.doc(item.id).set(item.toMap());
    return item;
  }

  static Future<void> setPublished(String id, bool value) async {
    if (!FirebaseService.isAvailable) return;
    await _col.doc(id).update({'published': value});
  }

  static Future<void> deleteContent(String id) async {
    if (!FirebaseService.isAvailable) return;
    await _col.doc(id).delete();
  }
}
