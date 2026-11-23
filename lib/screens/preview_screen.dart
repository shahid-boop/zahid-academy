import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../services/app_state.dart';
import '../services/launcher_service.dart';
import '../widgets/file_tile.dart';

/// File ka detail + preview screen (view system).
class PreviewScreen extends StatelessWidget {
  final AppFile file;

  const PreviewScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);
    final locked = !app.canDownload(file.category, premium: file.isPremium);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('preview')),
        actions: [
          IconButton(
            tooltip: s.t('add_favorite'),
            onPressed: () => app.toggleFavorite(file.id),
            icon: Icon(
              app.favorites.contains(file.id) ? Icons.star : Icons.star_border,
              color: app.favorites.contains(file.id) ? Colors.amber : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(context, s),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _info(Icons.category_outlined, s.t('content_category'), file.category),
                  _info(Icons.insert_drive_file_outlined, s.t('type'), file.typeLabel),
                  _info(Icons.storage_outlined, s.t('size'), file.sizeLabel ?? '-'),
                  _info(Icons.calendar_today_outlined, s.t('date'), file.dateLabel),
                  if (file.isPremium)
                    _info(Icons.workspace_premium, s.t('premium_only'), s.t('paid_active')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: file.url == null
                      ? null
                      : () async {
                          final ok = await LauncherService.openUrl(file.url!);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.t('open_failed'))),
                            );
                          }
                        },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(s.t('open_file')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final messenger = ScaffoldMessenger.of(context);
                    app.download(file).then((outcome) {
                      final key = switch (outcome) {
                        DownloadOutcome.opened => 'download_started',
                        DownloadOutcome.noUrl => 'no_url',
                        DownloadOutcome.failed => 'open_failed',
                        DownloadOutcome.lockedTrial => 'trial_limit',
                        DownloadOutcome.lockedExpired => 'trial_expired',
                        DownloadOutcome.lockedPremium => 'locked_premium',
                        DownloadOutcome.lockedSubscribe => 'subscribe_first',
                      };
                      messenger.showSnackBar(SnackBar(content: Text(s.t(key))));
                    });
                  },
                  icon: Icon(locked ? Icons.lock : Icons.download),
                  label: Text(locked ? s.t('locked') : s.t('download')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            s.t('library'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          ...app.contents
              .where((f) => f.category == file.category && f.id != file.id)
              .take(5)
              .map((f) => FileTile(file: f)),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, S s) {
    final isImage = file.kind == FileKind.image ||
        (file.thumbnailUrl ?? '').toLowerCase().endsWith('.png') ||
        (file.thumbnailUrl ?? '').toLowerCase().endsWith('.jpg');

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A2540),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isImage && file.thumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                file.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iconPlaceholder(context, s),
              ),
            )
          : _iconPlaceholder(context, s),
    );
  }

  Widget _iconPlaceholder(BuildContext context, S s) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(file.icon, size: 72, color: Colors.white),
        const SizedBox(height: 10),
        Text(
          file.typeLabel,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
