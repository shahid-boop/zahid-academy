import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/app_data.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../widgets/file_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    final files = app.favorites
        .map((id) {
          final remote = app.contents.where((f) => f.id == id);
          return remote.isEmpty ? AppData.byId[id] : remote.first;
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
              Icon(Icons.star_border, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                s.t('no_favorites'),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${s.t('favorites')}  •  ${files.length}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...files.map((file) => FileTile(file: file)),
      ],
    );
  }
}
