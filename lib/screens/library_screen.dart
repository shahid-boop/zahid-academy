import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../services/content_repository.dart';
import '../widgets/file_tile.dart';

class LibraryScreen extends StatefulWidget {
  final String? initialQuery;

  const LibraryScreen({super.key, this.initialQuery});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  String _sort = 'date';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _search.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static double _sizeKb(String? label) {
    if (label == null) return 0;
    final value = double.tryParse(label.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return label.toLowerCase().contains('mb') ? value * 1024 : value;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    var items = ContentRepository.search(app.contents, _search.text);
    if (_filter != 'all') {
      items = items.where((f) => f.typeLabel == _filter).toList();
    }
    switch (_sort) {
      case 'name':
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'size':
        items.sort((a, b) => _sizeKb(b.sizeLabel).compareTo(_sizeKb(a.sizeLabel)));
        break;
      default:
        items.sort((a, b) =>
            (b.publishedAtMs ?? 0).compareTo(a.publishedAtMs ?? 0));
    }

    final types = <String>{for (final f in app.contents) f.typeLabel}.toList()
      ..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: s.t('search_hint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.sort, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              DropdownButton<String>(
                value: _sort,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'date', child: Text(s.t('sort_date'))),
                  DropdownMenuItem(value: 'name', child: Text(s.t('sort_name'))),
                  DropdownMenuItem(value: 'size', child: Text(s.t('sort_size'))),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
              ),
              const Spacer(),
              Text('${items.length} ${s.t('items')}'),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(s.t('all')),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
              ),
              for (final type in types)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(type),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(s.t('no_contents')))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  itemCount: items.length,
                  itemBuilder: (_, i) =>
                      FileTile(file: items[i], showPreview: true),
                ),
        ),
      ],
    );
  }
}
