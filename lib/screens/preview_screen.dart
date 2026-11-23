import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';

import '../app_scope.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../services/app_state.dart';
import '../services/launcher_service.dart';
import '../widgets/file_tile.dart';

/// Har file ka detail + **inline viewer** (PDF / video / image).
class PreviewScreen extends StatefulWidget {
  final AppFile file;

  const PreviewScreen({super.key, required this.file});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);
    final file = widget.file;
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
          Text(
            s.t('preview'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _viewer(context, s),
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          ...app.contents
              .where((f) => f.category == file.category && f.id != file.id)
              .take(5)
              .map((f) => FileTile(file: f)),
        ],
      ),
    );
  }

  Widget _viewer(BuildContext context, S s) {
    final file = widget.file;
    final url = file.url;

    if (url == null || url.isEmpty) {
      return _placeholder(context, s, s.t('no_url'));
    }

    switch (file.kind) {
      case FileKind.lecture: // PDF
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 460,
            child: PDFView(
              url: url,
              autoPlay: false,
              onError: (_) => _placeholder(context, s, s.t('open_failed')),
            ),
          ),
        );

      case FileKind.video:
        return Card(
          clipBehavior: Clip.antiAlias,
          child: _VideoViewer(url: url),
        );

      case FileKind.image:
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 320,
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    _placeholder(context, s, s.t('open_failed')),
              ),
            ),
          ),
        );

      default:
        // DWG / DXF / 3D Max / SketchUp ko phone par render nahi kar sakte.
        return _placeholder(context, s, s.t('open_file'));
    }
  }

  Widget _hero(BuildContext context, S s) {
    final file = widget.file;
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A2540),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(file.icon, size: 64, color: Colors.white),
      ),
    );
  }

  Widget _placeholder(BuildContext context, S s, String message) {
    return Card(
      child: Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.file.icon, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
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

/// Video inline player with play/pause.
class _VideoViewer extends StatefulWidget {
  final String url;

  const _VideoViewer({required this.url});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  late final VideoPlayerController _controller;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const SizedBox(
        height: 180,
        child: Center(child: Icon(Icons.broken_image, size: 48)),
      );
    }
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ratio = _controller.value.aspectRatio;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: (ratio > 0 && ratio.isFinite) ? ratio : 16 / 9,
          child: VideoPlayer(_controller),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          icon: Icon(
            _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
            size: 32,
          ),
        ),
      ],
    );
  }
}
