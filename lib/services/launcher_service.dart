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
    // Normalize: 03001234567 -> 923001234567, 3001234567 -> 923001234567
    var clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0') && clean.length > 1) {
      clean = '92${clean.substring(1)}';
    } else if (clean.length == 10 && clean.startsWith('3')) {
      clean = '92$clean';
    }
    if (clean.isEmpty) return false;

    final encoded = Uri.encodeComponent(text);

    // 1) Direct WhatsApp app (best when installed).
    final direct = Uri.parse('whatsapp://send?phone=$clean&text=$encoded');
    try {
      if (await canLaunchUrl(direct)) {
        if (await launchUrl(direct, mode: LaunchMode.externalApplication)) {
          return true;
        }
      }
    } catch (_) {}

    // 2) wa.me deep link (works with browser / app).
    if (await openUrl('https://wa.me/$clean?text=$encoded')) return true;

    // 3) Fallback to WhatsApp web.
    return openUrl(
      'https://api.whatsapp.com/send?phone=$clean&text=$encoded',
    );
  }
}
