/// Download history ka ek record.
class DownloadRecord {
  final String fileId;
  final int timeMs;

  const DownloadRecord({required this.fileId, required this.timeMs});

  String toStorage() => '$fileId|$timeMs';

  static DownloadRecord? fromStorage(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    final time = int.tryParse(parts[1]);
    if (time == null || parts[0].isEmpty) return null;
    return DownloadRecord(fileId: parts[0], timeMs: time);
  }
}
