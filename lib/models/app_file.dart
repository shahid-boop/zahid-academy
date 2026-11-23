import 'package:flutter/material.dart';

/// Har downloadable item ka type.
enum FileKind { lecture, drawing, video, dwg, dxf, max3d, sketchup, map, image }

/// App ka core content model. Local data aur Firestore dono se banta hai.
class AppFile {
  final String id;
  final String name;
  final String category;
  final FileKind kind;
  final String? url;

  // Firestore / library metadata
  final String? sizeLabel;
  final int? publishedAtMs;
  final bool isPremium;
  final bool published;
  final String? thumbnailUrl;

  const AppFile({
    required this.id,
    required this.name,
    required this.category,
    required this.kind,
    this.url,
    this.sizeLabel,
    this.publishedAtMs,
    this.isPremium = false,
    this.published = true,
    this.thumbnailUrl,
  });

  factory AppFile.fromMap(String id, Map<String, dynamic> map) {
    return AppFile(
      id: id,
      name: (map['name'] ?? map['title'] ?? 'Untitled').toString(),
      category: (map['category'] ?? 'Library').toString(),
      kind: _kindFromString(map['kind']?.toString()),
      url: map['url']?.toString(),
      sizeLabel: map['sizeLabel']?.toString(),
      publishedAtMs: map['publishedAtMs'] is int
          ? map['publishedAtMs'] as int
          : int.tryParse(map['publishedAtMs']?.toString() ?? ''),
      isPremium: map['isPremium'] == true,
      published: map['published'] != false,
      thumbnailUrl: map['thumbnailUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'title': name,
        'category': category,
        'kind': kind.name,
        'url': url,
        'sizeLabel': sizeLabel,
        'publishedAtMs': publishedAtMs,
        'isPremium': isPremium,
        'published': published,
        'thumbnailUrl': thumbnailUrl,
      };

  static FileKind _kindFromString(String? value) {
    switch (value) {
      case 'lecture':
      case 'pdf':
        return FileKind.lecture;
      case 'drawing':
        return FileKind.drawing;
      case 'video':
        return FileKind.video;
      case 'dwg':
        return FileKind.dwg;
      case 'dxf':
        return FileKind.dxf;
      case 'max3d':
        return FileKind.max3d;
      case 'sketchup':
        return FileKind.sketchup;
      case 'map':
        return FileKind.map;
      case 'image':
        return FileKind.image;
      default:
        return FileKind.lecture;
    }
  }

  IconData get icon {
    switch (kind) {
      case FileKind.lecture:
        return Icons.picture_as_pdf_outlined;
      case FileKind.drawing:
        return Icons.draw_outlined;
      case FileKind.video:
        return Icons.play_circle_outline;
      case FileKind.dwg:
        return Icons.auto_stories_outlined;
      case FileKind.dxf:
        return Icons.description_outlined;
      case FileKind.max3d:
        return Icons.view_in_ar_outlined;
      case FileKind.sketchup:
        return Icons.cube;
      case FileKind.map:
        return Icons.map_outlined;
      case FileKind.image:
        return Icons.image_outlined;
    }
  }

  String get typeLabel {
    switch (kind) {
      case FileKind.lecture:
        return 'PDF';
      case FileKind.drawing:
        return 'DRAWING';
      case FileKind.video:
        return 'VIDEO';
      case FileKind.dwg:
        return 'DWG';
      case FileKind.dxf:
        return 'DXF';
      case FileKind.max3d:
        return '3D MAX';
      case FileKind.sketchup:
        return 'SKETCHUP';
      case FileKind.map:
        return 'MAP';
      case FileKind.image:
        return 'IMAGE';
    }
  }

  String get dateLabel {
    if (publishedAtMs == null) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(publishedAtMs!);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  AppFile copyWith({bool? published, bool? isPremium}) => AppFile(
        id: id,
        name: name,
        category: category,
        kind: kind,
        url: url,
        sizeLabel: sizeLabel,
        publishedAtMs: publishedAtMs,
        isPremium: isPremium ?? this.isPremium,
        published: published ?? this.published,
        thumbnailUrl: thumbnailUrl,
      );
}
