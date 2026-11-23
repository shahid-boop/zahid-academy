import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/strings.dart';
import '../services/app_state.dart';
import '../widgets/payment_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _whatsapp;
  late final TextEditingController _jazzcash;
  late final TextEditingController _easypaisa;
  late final TextEditingController _baseUrl;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _whatsapp = TextEditingController(text: app.whatsappNumber);
    _jazzcash = TextEditingController(text: app.jazzcashNumber);
    _easypaisa = TextEditingController(text: app.easypaisaNumber);
    _baseUrl = TextEditingController(text: app.downloadBaseUrl);
  }

  @override
  void dispose() {
    _whatsapp.dispose();
    _jazzcash.dispose();
    _easypaisa.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        _sectionCard(
          icon: Icons.language,
          title: s.t('language'),
          child: Row(
            children: [
              for (final code in ['EN', 'UR', 'AR'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(
                        code == 'EN' ? 'English' : code == 'UR' ? 'اردو' : 'العربية',
                      ),
                      selected: app.lang == code,
                      onSelected: (_) => app.setLang(code),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _subscriptionCard(app, s),
        const SizedBox(height: 12),
        _contactCard(app, s),
        const SizedBox(height: 12),
        _sectionCard(
          icon: Icons.info_outlined,
          title: s.t('about'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('about_text')),
              const SizedBox(height: 8),
              Text(
                s.t('version'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _subscriptionCard(AppState app, S s) {
    final active = app.hasPaidAccess;
    return _sectionCard(
      icon: Icons.workspace_premium_outlined,
      title: s.t('subscription'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.check_circle : Icons.radio_button_unchecked,
                color: active ? Colors.green : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                active ? s.t('paid_active') : s.t('subscription_inactive'),
                style: TextStyle(
                  color: active ? Colors.green.shade700 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!active) ...[
            const SizedBox(height: 8),
            Text(
              app.trialActive
                  ? '${app.trialDaysLeft} ${s.t('days_left')}'
                  : s.t('trial_expired'),
            ),
          ],
          const SizedBox(height: 12),
          Text(s.t('monthly_fee')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showPaymentRequestDialog(
                    context: context,
                    app: app,
                    s: s,
                    method: 'jazzcash',
                    number: app.jazzcashNumber,
                  ),
                  child: Text(s.t('jazzcash')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => showPaymentRequestDialog(
                    context: context,
                    app: app,
                    s: s,
                    method: 'easypaisa',
                    number: app.easypaisaNumber,
                  ),
                  child: Text(s.t('easypaisa')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                app.resetTrial();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.t('reset_done'))),
                );
              },
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(s.t('reset_trial')),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('demo_note'),
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(AppState app, S s) {
    return _sectionCard(
      icon: Icons.contacts_outlined,
      title: s.t('contact_numbers'),
      child: Column(
        children: [
          TextField(
            controller: _whatsapp,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: s.t('whatsapp_number')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _jazzcash,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: s.t('jazzcash_number')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _easypaisa,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: s.t('easypaisa_number')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _baseUrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: s.t('base_url'),
              hintText: s.t('base_url_hint'),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _save(app, s),
              icon: const Icon(Icons.save_outlined),
              label: Text(s.t('save')),
            ),
          ),
        ],
      ),
    );
  }

  void _save(AppState app, S s) {
    final messenger = ScaffoldMessenger.of(context);
    final wa = _whatsapp.text.replaceAll(RegExp(r'[^0-9]'), '');
    final jc = _jazzcash.text.replaceAll(RegExp(r'[^0-9]'), '');
    final ep = _easypaisa.text.replaceAll(RegExp(r'[^0-9]'), '');
    final base = _baseUrl.text.trim();

    if (wa.isEmpty || jc.isEmpty || ep.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(s.t('invalid_number'))));
      return;
    }
    if (base.isNotEmpty) {
      final uri = Uri.tryParse(base);
      if (uri == null ||
          !uri.hasScheme ||
          !(uri.scheme == 'http' || uri.scheme == 'https') ||
          !uri.hasHost) {
        messenger.showSnackBar(SnackBar(content: Text(s.t('invalid_url'))));
        return;
      }
    }

    app.saveContactInfo(
      whatsapp: wa,
      jazzcash: jc,
      easypaisa: ep,
      baseUrl: base,
    );
    messenger.showSnackBar(SnackBar(content: Text(s.t('saved'))));
  }
}
