import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_file.dart';
import '../models/app_user.dart';
import '../models/download_record.dart';
import '../models/payment_request.dart';
import 'auth_service.dart';
import 'content_repository.dart';
import 'launcher_service.dart';
import 'payment_service.dart';
import 'storage_service.dart';

enum DownloadOutcome {
  opened,
  noUrl,
  failed,
  lockedTrial,
  lockedExpired,
  lockedPremium,
  lockedSubscribe,
}

class AppNotification {
  final String titleKey;
  final String bodyKey;

  const AppNotification({required this.titleKey, required this.bodyKey});
}

/// Poori app ka state. Koi bhi change UI ko notify karta hai.
class AppState extends ChangeNotifier {
  final StorageService _storage;

  static const int trialDays = 7;
  static const int maxHistory = 200;
  static const int accessDays = 30;

  AppState(this._storage) {
    _load();
    _listenAuth();
    _listenContent();
  }

  // --- local persisted state ---
  bool isSubscribed = false; // legacy flag, ab use nahi hota (payments se access)
  int? trialStartMs;
  final Map<String, int> trialDownloads = <String, int>{};
  final Set<String> favorites = <String>{};
  final List<DownloadRecord> history = <DownloadRecord>[];

  String selectedSize = '5 Marla';
  String lang = 'EN'; // EN | UR | AR
  String whatsappNumber = '0346-7803931';
  String jazzcashNumber = '';
  String easypaisaNumber = '';
  String downloadBaseUrl = '';

  // --- live state ---
  AppUser? user;
  List<AppFile> contents = const <AppFile>[];
  List<PaymentRequest> myRequests = const <PaymentRequest>[];

  StreamSubscription<AppUser?>? _authSub;
  StreamSubscription<List<AppFile>>? _contentSub;
  StreamSubscription<List<PaymentRequest>>? _paymentSub;

  void _load() {
    trialStartMs = _storage.getInt(StorageService.kTrialStart);
    if (trialStartMs == null) {
      trialStartMs = DateTime.now().millisecondsSinceEpoch;
      _storage.setInt(StorageService.kTrialStart, trialStartMs!);
    }

    for (final raw in _storage.getList(StorageService.kTrialDownloads)) {
      final parts = raw.split(':');
      if (parts.length == 2) {
        trialDownloads[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    favorites.addAll(_storage.getList(StorageService.kFavorites));
    for (final raw in _storage.getList(StorageService.kHistory)) {
      final record = DownloadRecord.fromStorage(raw);
      if (record != null) history.add(record);
    }

    selectedSize = _storage.getString(StorageService.kSelectedSize) ?? '5 Marla';
    lang = _storage.getString(StorageService.kLang) ?? 'EN';
    whatsappNumber = _storage.getString(StorageService.kWhatsapp) ?? '';
    if (whatsappNumber.trim().isEmpty) {
      whatsappNumber = '0346-7803931';
    }
    jazzcashNumber = _storage.getString(StorageService.kJazzcash) ?? '';
    easypaisaNumber = _storage.getString(StorageService.kEasypaisa) ?? '';
    downloadBaseUrl = _storage.getString(StorageService.kBaseUrl) ?? '';
  }

  void _listenAuth() {
    _authSub?.cancel();
    _authSub = AuthService.authChanges.listen(
      (appUser) {
        user = appUser;
        _listenPayments(appUser?.uid);
        notifyListeners();
      },
      onError: (_) {
        user = null;
        notifyListeners();
      },
    );
  }

  void _listenContent() {
    _contentSub?.cancel();
    _contentSub = ContentRepository.watchAll().listen(
      (items) {
        contents = items;
        notifyListeners();
      },
      onError: (_) {
        // Repository khud local fallback bhejta hai; yahan kuch nahi.
      },
    );
  }

  void _listenPayments(String? uid) {
    _paymentSub?.cancel();
    if (uid == null) {
      myRequests = const <PaymentRequest>[];
      notifyListeners();
      return;
    }
    _paymentSub = PaymentService.watchMyRequests(uid).listen(
      (requests) {
        myRequests = requests;
        notifyListeners();
      },
      onError: (_) {
        myRequests = const <PaymentRequest>[];
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _contentSub?.cancel();
    _paymentSub?.cancel();
    super.dispose();
  }

  // --- computed ---

  bool get isUrdu => lang == 'UR';
  bool get isArabic => lang == 'AR';
  bool get isRtl => lang == 'AR';

  bool get trialActive {
    if (trialStartMs == null) return true;
    final elapsed = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(trialStartMs!))
        .inDays;
    return elapsed < trialDays;
  }

  int get trialDaysLeft {
    if (trialStartMs == null) return trialDays;
    final elapsed = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(trialStartMs!))
        .inDays;
    final left = trialDays - elapsed;
    return left < 0 ? 0 : (left > trialDays ? trialDays : left);
  }

  /// Sirf approved (aur expire na hua) payment paid access deti hai.
  bool get hasPaidAccess => myRequests.any(
        (r) =>
            r.status == PaymentStatus.approved &&
            (r.reviewedAtMs == null ||
                DateTime.now().millisecondsSinceEpoch <
                    r.reviewedAtMs! + accessDays * 24 * 60 * 60 * 1000),
      );

  int? get paidExpiryMs {
    final approved = myRequests
        .where((r) => r.status == PaymentStatus.approved && r.reviewedAtMs != null)
        .toList()
      ..sort((a, b) => b.reviewedAtMs!.compareTo(a.reviewedAtMs!));
    if (approved.isEmpty) return null;
    return approved.first.reviewedAtMs! + accessDays * 24 * 60 * 60 * 1000;
  }

  int downloadsUsed(String category) => trialDownloads[category] ?? 0;

  bool canDownload(String category, {bool premium = false}) {
    if (premium && !hasPaidAccess) return false;
    if (hasPaidAccess) return true;
    if (!trialActive) return false;
    return downloadsUsed(category) < 1;
  }

  int remainingFor(String category) {
    if (hasPaidAccess) return 20;
    if (!trialActive) return 0;
    return downloadsUsed(category) < 1 ? 1 : 0;
  }

  List<AppNotification> get notifications {
    final list = <AppNotification>[];
    if (!trialActive) {
      list.add(
        const AppNotification(
          titleKey: 'notif_expired_title',
          bodyKey: 'notif_expired_body',
        ),
      );
    } else if (trialDaysLeft <= 2) {
      list.add(
        const AppNotification(
          titleKey: 'notif_trial_end_title',
          bodyKey: 'notif_trial_end_body',
        ),
      );
    }
    for (final request in myRequests) {
      if (request.status == PaymentStatus.approved) {
        list.add(
          const AppNotification(
            titleKey: 'notif_approved_title',
            bodyKey: 'notif_approved_body',
          ),
        );
      } else if (request.status == PaymentStatus.rejected) {
        list.add(
          const AppNotification(
            titleKey: 'notif_rejected_title',
            bodyKey: 'notif_rejected_body',
          ),
        );
      }
    }
    return list;
  }

  int get unreadCount => notifications.length;

  // --- actions ---

  Future<DownloadOutcome> download(AppFile file) async {
    if (file.isPremium && !hasPaidAccess) {
      return DownloadOutcome.lockedPremium;
    }
    if (hasPaidAccess) {
      // allowed
    } else if (!trialActive) {
      return DownloadOutcome.lockedExpired;
    } else if (downloadsUsed(file.category) >= 1) {
      return DownloadOutcome.lockedTrial;
    }

    trialDownloads[file.category] = downloadsUsed(file.category) + 1;
    await _storage.setList(StorageService.kTrialDownloads, _encodeTrial());

    history.insert(
      0,
      DownloadRecord(
        fileId: file.id,
        timeMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (history.length > maxHistory) {
      history.removeRange(maxHistory, history.length);
    }
    await _storage.setList(
      StorageService.kHistory,
      history.map((r) => r.toStorage()).toList(),
    );
    notifyListeners();

    final url = _resolveUrl(file);
    if (url == null || url.isEmpty) return DownloadOutcome.noUrl;
    final opened = await LauncherService.openUrl(url);
    return opened ? DownloadOutcome.opened : DownloadOutcome.failed;
  }

  String? _resolveUrl(AppFile file) {
    if (file.url != null && file.url!.trim().isNotEmpty) {
      return file.url!.trim();
    }
    final base = downloadBaseUrl.trim();
    if (base.isEmpty) return null;
    final cleanBase = base.replaceAll(RegExp(r'/+$'), '');
    return '$cleanBase/${Uri.encodeComponent(file.id)}';
  }

  List<String> _encodeTrial() => trialDownloads.entries
      .map((entry) => '${entry.key}:${entry.value}')
      .toList();

  Future<void> setSelectedSize(String size) async {
    selectedSize = size;
    await _storage.setString(StorageService.kSelectedSize, size);
    notifyListeners();
  }

  Future<void> toggleLang() async {
    lang = switch (lang) {
      'EN' => 'UR',
      'UR' => 'AR',
      _ => 'EN',
    };
    await _storage.setString(StorageService.kLang, lang);
    notifyListeners();
  }

  Future<void> setLang(String code) async {
    if (code != 'EN' && code != 'UR' && code != 'AR') return;
    if (lang == code) return;
    lang = code;
    await _storage.setString(StorageService.kLang, lang);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    await _storage.setList(StorageService.kFavorites, favorites.toList());
    notifyListeners();
  }

  /// Demo purpose: sirf trial reset karta hai, paid access nahi deta.
  Future<void> resetTrial() async {
    trialStartMs = DateTime.now().millisecondsSinceEpoch;
    trialDownloads.clear();
    await _storage.setInt(StorageService.kTrialStart, trialStartMs!);
    await _storage.setList(StorageService.kTrialDownloads, const <String>[]);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history.clear();
    await _storage.setList(StorageService.kHistory, const <String>[]);
    notifyListeners();
  }

  Future<void> saveContactInfo({
    required String whatsapp,
    required String jazzcash,
    required String easypaisa,
    required String baseUrl,
  }) async {
    whatsappNumber = whatsapp.trim();
    jazzcashNumber = jazzcash.trim();
    easypaisaNumber = easypaisa.trim();
    downloadBaseUrl = baseUrl.trim();
    await _storage.setString(StorageService.kWhatsapp, whatsappNumber);
    await _storage.setString(StorageService.kJazzcash, jazzcashNumber);
    await _storage.setString(StorageService.kEasypaisa, easypaisaNumber);
    await _storage.setString(StorageService.kBaseUrl, downloadBaseUrl);
    notifyListeners();
  }

  Future<bool> openWhatsApp(String message) {
    return LauncherService.openWhatsApp(number: whatsappNumber, text: message);
  }

  // --- auth / payment wrappers ---

  Future<AppUser> signIn(String email, String password) =>
      AuthService.signIn(email: email, password: password);

  Future<AppUser> signUp(String email, String password, String name) =>
      AuthService.signUp(email: email, password: password, displayName: name);

  Future<void> signOut() => AuthService.signOut();

  Future<void> submitPaymentRequest({
    required String method,
    required String accountNumber,
    required String reference,
    XFile? screenshot,
    String? note,
  }) async {
    final current = user;
    if (current == null) {
      throw Exception('Payment request ke liye login zaroori hai.');
    }
    await PaymentService.submit(
      user: current,
      method: method,
      accountNumber: accountNumber,
      reference: reference,
      screenshot: screenshot,
      note: note,
    );
  }

  Future<void> reviewPayment(PaymentRequest request, PaymentStatus status) async {
    final current = user;
    if (current == null) throw Exception('Admin login zaroori hai.');
    await PaymentService.review(
      admin: current,
      requestId: request.id,
      status: status,
    );
  }
}
