import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/app_data.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../services/app_state.dart';
import '../widgets/file_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    final files = app.history
        .map((record) {
          final remote = app.contents.where((f) => f.id == record.fileId);
          return remote.isEmpty ? AppData.byId[record.fileId] : remote.first;
        })
        .whereType<AppFile>()
        .toList();

    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                s.t('no_history'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${s.t('history')}  •  ${files.length}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: () => _confirmClear(context, app, s),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(s.t('clear_history')),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...files.map((file) => FileTile(file: file)),
      ],
    );
  }

  void _confirmClear(BuildContext context, AppState app, S s) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(s.t('clear_history')),
        content: Text(s.t('confirm_clear')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              app.clearHistory();
              Navigator.pop(ctx);
            },
            child: Text(s.t('clear_history')),
          ),
        ],
      ),
    );
  }
}
