import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/torrent_result.dart';

class TorrentSomeService {
  static const String tmdbApiKey = 'd56e51fb77b081a9cb5192eaaa7823ad';
  static const Map<String, String> headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7",
  };

  Future<String?> getOriginalTitle(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url =
        'https://api.themoviedb.org/3/search/multi?api_key=$tmdbApiKey&query=$encodedQuery';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      if (results.isNotEmpty) {
        return results[0]['original_name'] ?? results[0]['original_title'];
      }
    }
    return null;
  }

  Future<List<TorrentResult>> search(String query) async {
    // 1. Get original title from TMDB
    final originalTitle = await getOriginalTitle(query);
    if (originalTitle == null) return [];

    // 2. Search on TorrentSome
    final encodedName = Uri.encodeComponent(originalTitle);
    final searchUrl =
        'https://torrentsome230.com/search/index?keywords=$encodedName&search_type=0';

    final response = await http.get(Uri.parse(searchUrl), headers: headers);
    if (response.statusCode != 200) return [];

    final document = parser.parse(response.body);
    final items = document.querySelectorAll('div.topic-item');

    List<TorrentResult> results = [];

    for (final item in items) {
      final titleAnchor = item.querySelector('div.flex-auto a');
      if (titleAnchor == null) continue;

      final title = titleAnchor.attributes['title'] ?? titleAnchor.text.trim();
      final detailHref = titleAnchor.attributes['href'];
      if (detailHref == null) continue;

      final sizeElements = item.querySelectorAll('div.flex-none.w-16');
      final size = sizeElements.isNotEmpty
          ? sizeElements[0].text.trim()
          : "N/A";

      results.add(
        TorrentResult(
          title: title,
          cleanedTitle: title,
          size: size,
          detailUrl: 'https://torrentsome230.com$detailHref',
          engine: 'torrentsome',
        ),
      );
    }

    return results;
  }

  Future<String?> fetchMagnet(String detailUrl) async {
    try {
      final response = await http.get(Uri.parse(detailUrl), headers: headers);
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final magnetAnchor = document.querySelector('a[href^="magnet:"]');
        return magnetAnchor?.attributes['href'];
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }
}
