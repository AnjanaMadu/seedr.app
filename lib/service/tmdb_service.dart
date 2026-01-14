import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tmdb_models.dart';

class TmdbService {
  static const String apiKey = 'd56e51fb77b081a9cb5192eaaa7823ad';
  static const String baseUrl = 'https://api.themoviedb.org/3';

  Future<List<TmdbMedia>> searchMulti(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = '$baseUrl/search/multi?api_key=$apiKey&query=$encodedQuery';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results
          .where(
            (item) =>
                item['media_type'] == 'tv' || item['media_type'] == 'movie',
          )
          .map((item) => TmdbMedia.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<TmdbDetails?> getDetails(int id, String mediaType) async {
    final url = '$baseUrl/$mediaType/$id?api_key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return TmdbDetails.fromJson(data);
    }
    return null;
  }
}
