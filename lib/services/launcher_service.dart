import 'package:url_launcher/url_launcher.dart';

/// URLs / WhatsApp kholne ka safe wrapper.
class LauncherService {
  LauncherService._();

  static Future<bool> openUrl(String raw) async {
    final url = raw.trim();
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    // Pehle external app (browser / drive / etc.) se kholne ki koshish.
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    } catch (_) {
      // Fallback neeche.
    }

    // Agar external fail ho to in-app browser / default mode.
    try {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openWhatsApp({
    required String number,
    required String text,
  }) async {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return false;
    final encoded = Uri.encodeComponent(text);
    return openUrl('https://wa.me/$clean?text=$encoded');
  }
}
