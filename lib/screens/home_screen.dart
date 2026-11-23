import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/app_data.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../services/app_state.dart';
import '../widgets/file_tile.dart';
import '../widgets/payment_dialog.dart';
import 'library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final value = _searchController.text.trim().toLowerCase();
    if (value != _query) setState(() => _query = value);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<AppFile> _filter(List<AppFile> source) {
    if (_query.isEmpty) return source;
    return source
        .where(
          (f) =>
              f.name.toLowerCase().contains(_query) ||
              f.category.toLowerCase().contains(_query) ||
              f.typeLabel.toLowerCase().contains(_query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);
    final searching = _query.isNotEmpty;
    final maps = app.contents
        .where((f) => f.category == 'Maps - ${app.selectedSize}')
        .toList();
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        _header(app, s),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: s.t('search_hint'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searching
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (!searching) ...[
          _promoCard(app, s),
          const SizedBox(height: 18),
          Text(s.t('categories'), style: titleStyle),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final category in AppData.homeCategories)
                _categoryCard(app, s, category),
            ],
          ),
          const SizedBox(height: 18),
          Text(s.t('recent_lessons'), style: titleStyle),
          const SizedBox(height: 8),
          ..._recentLessons(app, s),
          const SizedBox(height: 18),
          Text(s.t('maps_section'), style: titleStyle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: AppData.sizes.map((size) {
              return ChoiceChip(
                label: Text('$size (20)'),
                selected: app.selectedSize == size,
                onSelected: (_) => app.setSelectedSize(size),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          ..._filter(maps).map((file) => FileTile(file: file)),
          const SizedBox(height: 18),
          Text(s.t('library_section'), style: titleStyle),
          for (final category in AppData.categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: Text(
                '$category  •  20 ${s.t('items')}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            ..._filter(
              app.contents.where((f) => f.category == category).toList(),
            ).map((file) => FileTile(file: file)),
          ],
        ] else ...[
          _searchResults(s),
        ],
      ],
    );
  }

  Widget _header(AppState app, S s) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF0A2540),
          child: Icon(
            app.user == null ? Icons.person_outline : Icons.account_circle,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.t('welcome')}, ${app.user?.displayName ?? s.t('guest')}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                app.hasPaidAccess ? s.t('paid_active') : s.t('trial_title'),
                style: TextStyle(
                  fontSize: 12,
                  color: app.hasPaidAccess ? Colors.green : Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(AppState app, S s, String category) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final internal = AppData.homeCategoryToInternal[category] ?? category;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LibraryScreen(initialQuery: internal),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(
                AppData.homeCategoryIcons[category] ?? Icons.folder,
                color: const Color(0xFFE67E22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _recentLessons(AppState app, S s) {
    final wantedIds = AppData.recentLessons.map((f) => f.id).toList();
    final items = <AppFile>[];
    for (final id in wantedIds) {
      final found = app.contents.where((f) => f.id == id);
      items.add(found.isEmpty
          ? AppData.byId[id] ?? AppData.recentLessons.first
          : found.first);
    }
    return items.map((file) => FileTile(file: file, showPreview: true)).toList();
  }

  Widget _searchResults(S s) {
    final results = _filter(AppData.allFiles);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(s.t('empty_search')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s.t('search_results')}  •  ${results.length}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...results.map((file) => FileTile(file: file)),
      ],
    );
  }

  Widget _promoCard(AppState app, S s) {
    String status;
    if (app.hasPaidAccess) {
      status = s.t('subscribed_status');
    } else if (!app.trialActive) {
      status = s.t('expired_status');
    } else {
      status =
          '${s.t('trial_status')}  •  ${app.trialDaysLeft} ${s.t('days_left')}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.t('trial_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(status, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 14),
          Text(
            s.t('subscribe_now'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD42A2A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => showPaymentRequestDialog(
                    context: context,
                    app: app,
                    s: s,
                    method: 'jazzcash',
                    number: app.jazzcashNumber,
                  ),
                  icon: const Icon(Icons.payment, size: 18),
                  label: Text(s.t('jazzcash')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => showPaymentRequestDialog(
                    context: context,
                    app: app,
                    s: s,
                    method: 'easypaisa',
                    number: app.easypaisaNumber,
                  ),
                  icon: const Icon(Icons.account_balance_wallet, size: 18),
                  label: Text(s.t('easypaisa')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: IconButton(
              tooltip: s.t('whatsapp_contact'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => app.openWhatsApp(
                'Assalam-o-Alaikum, Mujhe Zahid Architecture Academy ki Subscription chahiye',
              ),
              icon: const Icon(Icons.chat, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
