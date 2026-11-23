import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence ka single point. Pure storage, koi business logic nahi.
class StorageService {
  static const String kSubscribed = 'subscribed';
  static const String kSubscriptionExpiry = 'subscription_expiry_ms';
  static const String kTrialStart = 'trial_start_ms';
  static const String kTrialDownloads = 'trial_downloads';
  static const String kFavorites = 'favorites';
  static const String kHistory = 'history';
  static const String kSelectedSize = 'selected_size';
  static const String kLang = 'lang';
  static const String kWhatsapp = 'whatsapp_number';
  static const String kJazzcash = 'jazzcash_number';
  static const String kEasypaisa = 'easypaisa_number';
  static const String kBaseUrl = 'download_base_url';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);
  String? getString(String key) => _prefs.getString(key);
  List<String> getList(String key) => _prefs.getStringList(key) ?? const <String>[];

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  Future<bool> setList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
  Future<bool> remove(String key) => _prefs.remove(key);
}
