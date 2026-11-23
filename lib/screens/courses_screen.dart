import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/strings.dart';
import '../models/app_file.dart';
import '../widgets/file_tile.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  static const Map<String, String> _courses = {
    'AutoCAD Basics': 'DWG Files',
    '3D Max Interior Design': '3D Max',
    'House Mapping': 'Maps - 5 Marla',
    'DXF Drafting': 'DXF Files',
    'Architecture Lectures': 'Lectures',
    'Picture Gallery': 'Drawings',
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S(urdu: app.isUrdu, arabic: app.isArabic);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        Text(
          s.t('courses'),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (final entry in _courses.entries) ...[
          Card(
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0A2540),
                child: Text(
                  entry.key.substring(0, 1),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(entry.key),
              subtitle: Text(
                '${entry.value}  •  ${app.contents.where((f) => f.category == entry.value).length} ${s.t('items')}',
              ),
              children: [
                for (final file in app.contents
                    .where((f) => f.category == entry.value)
                    .take(20))
                  FileTile(file: file),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
