import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../app_scope.dart';
import '../data/app_data.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../models/payment_request.dart';
import '../services/app_state.dart';
import '../services/content_repository.dart';
import '../services/firebase_service.dart';
import '../services/payment_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    if (app.user == null || !app.user!.isAdmin) {
      return Center(child: Text(s.t('admin_only')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabBar(
          tabs: [
            Tab(text: s.t('payment_requests')),
            Tab(text: s.t('upload_content')),
          ],
        ),
        body: TabBarView(
          children: [
            _PaymentsTab(s: s),
            _ContentTab(s: s),
          ],
        ),
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final S s;
  const _PaymentsTab({required this.s});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    if (!FirebaseService.isAvailable) {
      return Center(child: Text(s.t('firebase_required')));
    }

    return StreamBuilder<List<PaymentRequest>>(
      stream: PaymentService.watchAllRequests(),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const <PaymentRequest>[];
        if (requests.isEmpty) {
          return Center(child: Text(s.t('no_requests')));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final r = requests[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          r.status == PaymentStatus.approved
                              ? Icons.check_circle
                              : r.status == PaymentStatus.rejected
                                  ? Icons.cancel
                                  : Icons.hourglass_empty,
                          color: r.status == PaymentStatus.approved
                              ? Colors.green
                              : r.status == PaymentStatus.rejected
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${r.method.toUpperCase()}  •  ${s.t(r.status.name)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(r.dateLabel, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${s.t('email')}: ${r.userEmail}'),
                    Text('${s.t('reference')}: ${r.reference}'),
                    Text('${s.t('jazzcash_number')}: ${r.accountNumber}'),
                    if (r.screenshotUrl != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: Image.network(
                          r.screenshotUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: r.status == PaymentStatus.pending
                                ? () => _review(app, r, PaymentStatus.rejected)
                                : null,
                            icon: const Icon(Icons.close),
                            label: Text(s.t('reject')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: r.status == PaymentStatus.pending
                                ? () => _review(app, r, PaymentStatus.approved)
                                : null,
                            icon: const Icon(Icons.check),
                            label: Text(s.t('approve')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _review(
    AppState app,
    PaymentRequest request,
    PaymentStatus status,
  ) async {
    await app.reviewPayment(request, status);
  }
}

class _ContentTab extends StatefulWidget {
  final S s;
  const _ContentTab({required this.s});

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> {
  PlatformFile? _picked;
  final TextEditingController _title = TextEditingController();
  String _category = AppData.categories.first;
  FileKind _kind = FileKind.lecture;
  bool _premium = false;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _picked = result.files.first);
    }
  }

  Future<void> _upload() async {
    final s = widget.s;
    final messenger = ScaffoldMessenger.of(context);
    if (_picked?.path == null) {
      messenger.showSnackBar(SnackBar(content: Text(s.t('select_file'))));
      return;
    }
    setState(() => _busy = true);
    try {
      await ContentRepository.uploadContent(
        filePath: _picked!.path!,
        fileName: _picked!.name,
        name: _title.text,
        category: _category,
        kind: _kind,
        isPremium: _premium,
      );
      if (mounted) {
        setState(() {
          _picked = null;
          _title.clear();
        });
      }
      messenger.showSnackBar(SnackBar(content: Text(s.t('saved'))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final app = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('upload_content'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(labelText: s.t('content_name')),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(labelText: s.t('content_category')),
                  items: [
                    ...AppData.categories,
                    ...AppData.sizes.map((size) => 'Maps - $size'),
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<FileKind>(
                  value: _kind,
                  decoration: InputDecoration(labelText: s.t('file_type')),
                  items: FileKind.values
                      .map((k) => DropdownMenuItem(value: k, child: Text(k.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _kind = v);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _premium,
                  title: Text(s.t('premium_only')),
                  onChanged: (v) => setState(() => _premium = v),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_picked?.name ?? s.t('select_file')),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _upload,
                    icon: _busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(s.t('upload_content')),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.t('library'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        for (final item in app.contents.where((f) => f.id.startsWith('up_')))
          Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                '${item.category}  •  ${item.published ? s.t('approved') : s.t('pending')}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      item.published ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => ContentRepository.setPublished(
                      item.id,
                      !item.published,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ContentRepository.deleteContent(item.id),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
