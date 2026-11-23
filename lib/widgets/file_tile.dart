import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../services/app_state.dart';
import '../services/launcher_service.dart';
import '../screens/preview_screen.dart';
import 'payment_dialog.dart';

class FileTile extends StatelessWidget {
  final AppFile file;
  final bool showPreview;

  const FileTile({super.key, required this.file, this.showPreview = false});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    final locked = !app.canDownload(file.category, premium: file.isPremium);
    final isFavorite = app.favorites.contains(file.id);
    final downloadCount =
        app.history.where((record) => record.fileId == file.id).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: locked ? const Color(0x1FF44336) : const Color(0x1F4CAF50),
          child: Icon(
            file.icon,
            color: locked ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (file.isPremium)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${file.typeLabel}  •  ${file.sizeLabel ?? '-'}  •  ${file.dateLabel}',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              downloadCount > 0
                  ? '${file.category}  •  ${s.t('downloaded')} × $downloadCount'
                  : file.category,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPreview && file.url != null)
              IconButton(
                tooltip: s.t('preview'),
                onPressed: () => _openPreview(context, app, s),
                icon: const Icon(Icons.visibility_outlined, size: 20),
              ),
            IconButton(
              tooltip: isFavorite ? s.t('remove_favorite') : s.t('add_favorite'),
              onPressed: () => app.toggleFavorite(file.id),
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : null,
              ),
            ),
            const SizedBox(width: 2),
            ElevatedButton.icon(
              onPressed: () => _handleDownload(context, app, s, locked),
              icon: Icon(locked ? Icons.lock : Icons.download, size: 16),
              label: Text(locked ? s.t('locked') : s.t('download')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPreview(BuildContext context, AppState app, S s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(file: file)),
    );
  }

  void _handleDownload(
    BuildContext context,
    AppState app,
    S s,
    bool locked,
  ) {
    if (locked) {
      _showLockedDialog(context, app, s);
      return;
    }

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
  }

  void _showLockedDialog(BuildContext context, AppState app, S s) {
    final reason = file.isPremium && !app.hasPaidAccess
        ? s.t('locked_premium')
        : (!app.trialActive
            ? s.t('trial_expired')
            : (app.downloadsUsed(file.category) >= 1
                ? s.t('trial_limit')
                : s.t('subscribe_first')));

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          icon: const Icon(Icons.lock_outline, color: Colors.orange),
          title: Text(s.t('subscribe_now')),
          content: Text(reason),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.t('close')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                showPaymentRequestDialog(
                  context: context,
                  app: app,
                  s: s,
                  method: 'jazzcash',
                  number: app.jazzcashNumber,
                );
              },
              child: Text(s.t('jazzcash')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                showPaymentRequestDialog(
                  context: context,
                  app: app,
                  s: s,
                  method: 'easypaisa',
                  number: app.easypaisaNumber,
                );
              },
              child: Text(s.t('easypaisa')),
            ),
          ],
        );
      },
    );
  }
}
