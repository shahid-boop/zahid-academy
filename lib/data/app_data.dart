import '../models/app_file.dart';

/// Local fallback data. Firebase configured hone par Firestore content isko override karta hai.
class AppData {
  AppData._();

  static const List<String> sizes = ['3 Marla', '5 Marla', '10 Marla', '1 Kanal'];

  static const Map<String, FileKind> _categoryKinds = {
    'Lectures': FileKind.lecture,
    'Drawings': FileKind.drawing,
    'Videos': FileKind.video,
    'DWG Files': FileKind.dwg,
    'DXF Files': FileKind.dxf,
    '3D Max': FileKind.max3d,
    'SketchUp': FileKind.sketchup,
  };

  static const List<String> categories = [
    'Lectures',
    'Drawings',
    'Videos',
    'DWG Files',
    'DXF Files',
    '3D Max',
    'SketchUp',
  ];

  /// Home screen category grid - exactly as required by the master prompt.
  static const List<String> homeCategories = [
    'PDF Lessons',
    'Videos',
    'Pictures Gallery',
    'Naqshay Maps',
    '3D Max Files',
    'DWG Files',
    'DXF Files',
  ];

  static const Map<String, String> homeCategoryToInternal = {
    'PDF Lessons': 'Lectures',
    'Videos': 'Videos',
    'Pictures Gallery': 'Drawings',
    'Naqshay Maps': 'Maps - 5 Marla',
    '3D Max Files': '3D Max',
    'DWG Files': 'DWG Files',
    'DXF Files': 'DXF Files',
  };

  static const Map<String, IconData> homeCategoryIcons = {
    'PDF Lessons': Icons.picture_as_pdf,
    'Videos': Icons.play_circle_fill,
    'Pictures Gallery': Icons.photo_library,
    'Naqshay Maps': Icons.map,
    '3D Max Files': Icons.view_in_ar,
    'DWG Files': Icons.auto_stories,
    'DXF Files': Icons.description,
  };

  static String _singular(String key) {
    switch (key) {
      case 'Lectures':
        return 'Lecture';
      case 'Drawings':
        return 'Drawing';
      case 'Videos':
        return 'Video';
      case 'DWG Files':
        return 'DWG File';
      case 'DXF Files':
        return 'DXF File';
      case '3D Max':
        return '3D Max Design';
      case 'SketchUp':
        return 'SketchUp File';
      default:
        return key;
    }
  }

  static String _safeId(String text) => text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

  static List<AppFile> _make20(String key, FileKind kind) {
    final sizes = ['820 KB', '1.4 MB', '2.1 MB', '3.6 MB'];
    return List.generate(20, (i) {
      final n = i + 1;
      return AppFile(
        id: 'lib_${_safeId(key)}_$n',
        name: '${_singular(key)} $n',
        category: key,
        kind: kind,
        sizeLabel: sizes[i % sizes.length],
        publishedAtMs:
            DateTime(2026, 11, 20 - (i % 20)).millisecondsSinceEpoch,
      );
    });
  }

  static List<AppFile> _mapsFor(String size) {
    return List.generate(20, (i) {
      final n = i + 1;
      return AppFile(
        id: 'map_${_safeId(size)}_$n',
        name: '$size Map $n',
        category: 'Maps - $size',
        kind: FileKind.map,
        sizeLabel: ['640 KB', '1.2 MB', '2.8 MB'][i % 3],
        publishedAtMs: DateTime(2026, 11, 18 - (i % 18)).millisecondsSinceEpoch,
      );
    });
  }

  /// Prompt me explicitly maujood 3 "Recent Lessons".
  static final List<AppFile> recentLessons = [
    AppFile(
      id: 'recent_autocad_floor_plan_dwg',
      name: 'AutoCAD Floor Plan DWG File',
      category: 'DWG Files',
      kind: FileKind.dwg,
      sizeLabel: '4.2 MB',
      publishedAtMs: DateTime(2026, 11, 12).millisecondsSinceEpoch,
    ),
    AppFile(
      id: 'recent_3dmax_interior',
      name: '3D Max Interior File',
      category: '3D Max',
      kind: FileKind.max3d,
      sizeLabel: '18.7 MB',
      publishedAtMs: DateTime(2026, 11, 10).millisecondsSinceEpoch,
    ),
    AppFile(
      id: 'recent_house_map_5marla_dxf',
      name: 'House Map 5 Marla DXF',
      category: 'DXF Files',
      kind: FileKind.dxf,
      sizeLabel: '1.1 MB',
      publishedAtMs: DateTime(2026, 11, 8).millisecondsSinceEpoch,
    ),
  ];

  static final Map<String, List<AppFile>> library = {
    for (final entry in _categoryKinds.entries)
      entry.key: _make20(entry.key, entry.value),
  };

  static final Map<String, List<AppFile>> maps = {
    for (final size in sizes) size: _mapsFor(size),
  };

  static final List<AppFile> allFiles = [
    ...recentLessons,
    ...library.values.expand((list) => list),
    ...maps.values.expand((list) => list),
  ];

  static final Map<String, AppFile> byId = {
    for (final file in allFiles) file.id: file,
  };
}
