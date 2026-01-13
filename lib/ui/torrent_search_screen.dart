import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../service/nyaa_service.dart';
import '../service/seedr.dart';

class TorrentSearchScreen extends StatefulWidget {
  const TorrentSearchScreen({super.key});

  @override
  State<TorrentSearchScreen> createState() => _TorrentSearchScreenState();
}

class _TorrentSearchScreenState extends State<TorrentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NyaaService _nyaaService = NyaaService();
  List<NyaaResult> _results = [];
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
      final results = await _nyaaService.search(_searchController.text.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          if (results.isEmpty) {
            _error = 'No results found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to fetch results: $e';
        });
      }
    }
  }

  Future<void> _addToSeedr(NyaaResult result) async {
    try {
      final seedr = context.read<Seedr>();
      final response = await seedr.addMagnet(result.magnet);

      if (mounted) {
        if (response['result'] == true || response['result'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to Seedr: ${result.cleanedTitle}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to add: ${response['error'] ?? 'Unknown error'}',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
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
            hintText: 'Search Anime...',
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
                    Icons.movie_filter_rounded,
                    size: 64,
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for torrents on Nyaa.si',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return _buildResultCard(result, colorScheme);
              },
            ),
    );
  }

  Widget _buildResultCard(NyaaResult result, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.cleanedTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              result.title,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoTag(Icons.save_rounded, result.size, colorScheme),
                const SizedBox(width: 12),
                _buildInfoTag(
                  Icons.arrow_upward_rounded,
                  '${result.seeders} seeders',
                  colorScheme,
                  isSeeders: true,
                ),
                const Spacer(),
                IconButton.filledTonal(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.magnet));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Magnet link copied!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: 'Copy Magnet',
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _addToSeedr(result),
                  tooltip: 'Add to Seedr',
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInfoTag(
    IconData icon,
    String label,
    ColorScheme colorScheme, {
    bool isSeeders = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isSeeders ? Colors.green : colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
