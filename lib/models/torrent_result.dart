class TorrentResult {
  final String title;
  final String cleanedTitle;
  final String size;
  final String? seeders;
  String? magnet;
  final String? detailUrl;
  final String? engine; // 'nyaa' or 'torrentsome'

  TorrentResult({
    required this.title,
    required this.cleanedTitle,
    required this.size,
    this.seeders,
    this.magnet,
    this.detailUrl,
    this.engine,
  });
}
