import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/torrent_result.dart';

class NyaaService {
  static const String baseUrl = 'https://nyaa.si/';

  Future<List<TorrentResult>> search(String query, {int page = 1}) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = '$baseUrl?f=0&c=0_0&q=$encodedQuery&p=$page';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load search results');
    }

    final document = parser.parse(response.body);
    final rows = document.querySelectorAll('tr.success, tr.default, tr.danger');

    return rows
        .map((row) {
          final tds = row.querySelectorAll('td');
          if (tds.length < 8) return null;

          // Extract Title
          final titleAnchor = tds[1].querySelectorAll('a').last;
          final originalTitle =
              titleAnchor.attributes['title'] ?? titleAnchor.text.trim();

          // Extract Magnet
          final magnetAnchor = tds[2].querySelector('a[href^="magnet:"]');
          final magnet = magnetAnchor?.attributes['href'] ?? '';

          // Extract Size
          final size = tds[3].text.trim();

          // Extract Seeders
          final seeders = tds[5].text.trim();

          return TorrentResult(
            title: originalTitle,
            cleanedTitle: _cleanTitle(originalTitle),
            size: size,
            seeders: seeders,
            magnet: magnet,
            engine: 'nyaa',
          );
        })
        .whereType<TorrentResult>()
        .toList();
  }

  String _cleanTitle(String title) {
    // 1. Extract quality (e.g., 1080p, 720p, 480p, 2160p)
    final qualityRegex = RegExp(
      r'\b(480p|720p|1080p|2160p|4k)\b',
      caseSensitive: false,
    );
    final match = qualityRegex.firstMatch(title);
    final quality = match?.group(0);

    // 2. Remove text inside [] and ()
    String cleaned = title.replaceAll(RegExp(r'\[.*?\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(.*?\)'), '');

    // 3. Clean up extra dots, underscores, and multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'[\._]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 4. If quality was removed but we found it earlier, add it back
    if (quality != null &&
        !cleaned.toLowerCase().contains(quality.toLowerCase())) {
      cleaned = '$cleaned $quality';
    }

    return cleaned;
  }
}
