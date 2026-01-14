import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../service/tmdb_service.dart';
import '../models/tmdb_models.dart';
import 'media_details_screen.dart';

class TorrentSearchScreen extends StatefulWidget {
  const TorrentSearchScreen({super.key});

  @override
  State<TorrentSearchScreen> createState() => _TorrentSearchScreenState();
}

class _TorrentSearchScreenState extends State<TorrentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TmdbService _tmdbService = TmdbService();

  List<TmdbMedia> _results = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      final results = await _tmdbService.searchMulti(
        _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          if (results.isEmpty) {
            _error = 'No shows or movies found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Search failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search Anime, KDramas, Movies...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                setState(() => _results = []);
              },
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.outline),
                ),
              ),
            )
          : _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Find your favorite anime or show',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final media = _results[index];
                return _buildMediaCard(media, colorScheme);
              },
            ),
    );
  }

  Widget _buildMediaCard(TmdbMedia media, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailsScreen(media: media),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poster
              if (media.posterPath != null)
                Image.network(
                  media.posterUrl!,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    color: colorScheme.surfaceVariant,
                    child: const Icon(Icons.movie_outlined),
                  ),
                )
              else
                Container(
                  width: 100,
                  color: colorScheme.surfaceVariant,
                  child: const Icon(Icons.movie_outlined),
                ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              media.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (media.voteAverage != null &&
                              media.voteAverage! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    media.voteAverage!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${media.mediaType.toUpperCase()} • ${media.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          media.overview ?? 'No summary available.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }
}
