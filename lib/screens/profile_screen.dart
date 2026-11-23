import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/strings.dart';
import '../models/payment_request.dart';
import '../services/app_state.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  bool _register = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    if (app.user == null) return _authForm(app, s);
    return _profile(app, s);
  }

  Widget _authForm(AppState app, S s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF0A2540),
            child: Icon(Icons.person, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _register ? s.t('register') : s.t('login'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (!FirebaseService.isAvailable) ...[
            const SizedBox(height: 12),
            Text(
              s.t('firebase_required'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          if (_register)
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: s.t('display_name')),
            ),
          if (_register) const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: s.t('email')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: s.t('password')),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : () => _submit(app, s),
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_register ? s.t('sign_up') : s.t('sign_in')),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _register = !_register),
            child: Text(_register ? s.t('login') : s.t('register')),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(AppState app, S s) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      if (_register) {
        await app.signUp(_email.text, _password.text, _name.text);
      } else {
        await app.signIn(_email.text, _password.text);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _profile(AppState app, S s) {
    final user = app.user!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFF0A2540),
                  child: Icon(Icons.account_circle, size: 42, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(user.email, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.badge_outlined, size: 16),
                      label: Text('${s.t('role')}: ${user.role}'),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: Icon(
                        app.hasPaidAccess ? Icons.check_circle : Icons.lock,
                        size: 16,
                        color: app.hasPaidAccess ? Colors.green : Colors.grey,
                      ),
                      label: Text(
                        app.hasPaidAccess ? s.t('paid_active') : s.t('subscription_inactive'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('my_payments'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (app.myRequests.isEmpty) Text(s.t('no_requests')),
                for (final request in app.myRequests)
                  ListTile(
                    leading: Icon(
                      request.status == PaymentStatus.approved
                          ? Icons.check_circle
                          : request.status == PaymentStatus.rejected
                              ? Icons.cancel
                              : Icons.hourglass_empty,
                      color: request.status == PaymentStatus.approved
                          ? Colors.green
                          : request.status == PaymentStatus.rejected
                              ? Colors.red
                              : Colors.orange,
                    ),
                    title: Text(
                      '${request.method.toUpperCase()}  •  ${request.dateLabel}',
                    ),
                    subtitle: Text('${request.reference}  •  ${s.t(request.status.name)}'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => app.signOut(),
            icon: const Icon(Icons.logout),
            label: Text(s.t('sign_out')),
          ),
        ),
      ],
    );
  }
}
