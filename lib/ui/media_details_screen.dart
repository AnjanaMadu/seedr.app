import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/tmdb_models.dart';
import '../models/torrent_result.dart';
import '../service/tmdb_service.dart';
import '../service/nyaa_service.dart';
import '../service/torrentsome_service.dart';
import '../service/seedr.dart';

class MediaDetailsScreen extends StatefulWidget {
  final TmdbMedia media;

  const MediaDetailsScreen({super.key, required this.media});

  @override
  State<MediaDetailsScreen> createState() => _MediaDetailsScreenState();
}

class _MediaDetailsScreenState extends State<MediaDetailsScreen>
    with SingleTickerProviderStateMixin {
  final TmdbService _tmdbService = TmdbService();
  final NyaaService _nyaaService = NyaaService();
  final TorrentSomeService _torrentSomeService = TorrentSomeService();

  late TabController _tabController;
  TmdbDetails? _details;
  List<TorrentResult> _torrents = [];
  bool _isLoadingDetails = true;
  bool _isLoadingTorrents = false;
  String? _torrentError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadDetails();
    _loadTorrents();
  }

  Future<void> _loadDetails() async {
    try {
      final details = await _tmdbService.getDetails(
        widget.media.id,
        widget.media.mediaType,
      );
      if (mounted) {
        setState(() {
          _details = details;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _loadTorrents() async {
    setState(() {
      _isLoadingTorrents = true;
      _torrentError = null;
    });

    try {
      // FIX: Use English name/title for Anime, as Nyaa mostly indexes English or Romaji.
      // Use original name (Hangul) for KDrama, or fallback to English if needed.
      final isAnime = widget.media.originCountry?.contains('JP') ?? false;
      final isKDrama = widget.media.originCountry?.contains('KR') ?? false;

      String query;
      if (isAnime) {
        query =
            widget.media.name ?? widget.media.title ?? widget.media.displayName;
      } else if (isKDrama) {
        // TorrentSome usually handles Hangul well, or the service converts it.
        // But let's try original name first if available.
        query = widget.media.displayOriginalName;
      } else {
        query = widget.media.displayName;
      }

      List<TorrentResult> results = [];
      if (isAnime) {
        results = await _nyaaService.search(query);
      } else if (isKDrama) {
        results = await _torrentSomeService.search(query);
      } else {
        // Fallback or potentially ask user/try both
        results = await _nyaaService.search(query);
      }

      if (mounted) {
        setState(() {
          _torrents = results;
          _isLoadingTorrents = false;
          if (results.isEmpty) _torrentError = 'No torrents found for "$query"';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTorrents = false;
          _torrentError = 'Failed to fetch torrents: $e';
        });
      }
    }
  }

  Future<void> _addToSeedr(TorrentResult result) async {
    String? magnet = result.magnet;
    if (magnet == null && result.detailUrl != null) {
      // Show local loading indicator for this action if we could, but for now just global or silent blocking?
      // Better to just await with a snackbar "Fetching magnet..."
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching magnet link...'),
          duration: Duration(seconds: 1),
        ),
      );
      magnet = await _torrentSomeService.fetchMagnet(result.detailUrl!);
    }

    if (magnet == null) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Magnet not available.')));
      return;
    }

    try {
      final seedr = context.read<Seedr>();
      final response = await seedr.addMagnet(magnet);
      if (mounted) {
        final success =
            response['result'] == true || response['result'] == 'success';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Added to Seedr: ${result.cleanedTitle}'
                  : 'Failed: ${response['error']}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              stretch: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.media.backdropPath != null)
                      Image.network(
                        widget.media.backdropUrl!,
                        fit: BoxFit.cover,
                      )
                    else if (widget.media.posterPath != null)
                      Image.network(widget.media.posterUrl!, fit: BoxFit.cover)
                    else
                      Container(color: colorScheme.surfaceVariant),

                    // Complex gradient for smoother blending
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            colorScheme.surface.withOpacity(0.8),
                            colorScheme.surface,
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Header with Title and Poster (Integrated)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (widget.media.posterPath != null)
                            Hero(
                              tag: 'poster_${widget.media.id}',
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.media.posterUrl!,
                                    width: 100,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.media.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: colorScheme.surface.withOpacity(
                                          0.8,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.media.displayOriginalName !=
                                    widget.media.displayName)
                                  Text(
                                    widget.media.displayOriginalName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (widget.media.voteAverage != null &&
                                        widget.media.voteAverage! > 0) ...[
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.media.voteAverage!
                                            .toStringAsFixed(1),
                                        style: textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Text(
                                      widget.media.year,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Loading bar for details
                    if (_isLoadingDetails)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(minHeight: 2),
                        ),
                      ),

                    // Status & Tagline
                    if (_details?.status != null ||
                        (_details?.tagline?.isNotEmpty ?? false))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_details?.status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _details!.status!.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (_details?.tagline?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 8),
                            Text(
                              '"${_details!.tagline}"',
                              style: textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Genres
                    if (_details != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _details!.genres
                            .map(
                              (g) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant.withOpacity(
                                    0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  g,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverTabHeader(
                TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Torrents'),
                  ],
                ),
                colorScheme.surface,
              ),
              pinned: true,
            ),
          ];
        },
        body: Container(
          color: colorScheme.surface,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Overview & Details
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Synopsis',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.media.overview ?? 'No synopsis available.',
                      style: textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_details != null) ...[
                      if (_details!.numberOfSeasons != null ||
                          _details!.numberOfEpisodes != null) ...[
                        Row(
                          children: [
                            if (_details!.numberOfSeasons != null)
                              _buildStatBox(
                                'Seasons',
                                _details!.numberOfSeasons.toString(),
                                colorScheme,
                                textTheme,
                              ),
                            if (_details!.numberOfSeasons != null)
                              const SizedBox(width: 16),
                            if (_details!.numberOfEpisodes != null)
                              _buildStatBox(
                                'Episodes',
                                _details!.numberOfEpisodes.toString(),
                                colorScheme,
                                textTheme,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_details!.seasons != null &&
                          _details!.seasons!.isNotEmpty) ...[
                        Text(
                          'Seasons',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: _details!.seasons!.length,
                            itemBuilder: (context, index) {
                              final season = _details!.seasons![index];
                              if (season.seasonNumber == 0)
                                return const SizedBox.shrink();
                              return Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: colorScheme.surface,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: season.posterPath != null
                                          ? Image.network(
                                              'https://image.tmdb.org/t/p/w200${season.posterPath}',
                                              height: 150,
                                              width: 120,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 150,
                                              width: 120,
                                              color: colorScheme.surfaceVariant,
                                              child: const Icon(Icons.tv),
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      season.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${season.episodeCount} Episodes',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),

              // Tab 2: Torrents
              Container(
                color: colorScheme.surface,
                child: _isLoadingTorrents
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Finding torrents...',
                              style: TextStyle(color: colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : _torrentError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _torrentError!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colorScheme.outline),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.tonalIcon(
                                onPressed: _loadTorrents,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _torrents.isEmpty
                    ? Center(
                        child: Text(
                          'No torrents found.',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          80 + bottomPadding,
                        ),
                        itemCount: _torrents.length,
                        itemBuilder: (context, index) {
                          final torrent = _torrents[index];
                          return _buildTorrentCard(torrent, colorScheme, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTorrentCard(
    TorrentResult torrent,
    ColorScheme colorScheme,
    int index,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.35),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () {}, // No direct tap action for the whole card, actions are in buttons
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                torrent.cleanedTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMiniChip(
                    Icons.storage_rounded,
                    torrent.size,
                    colorScheme,
                  ),
                  if (torrent.seeders != null) ...[
                    const SizedBox(width: 8),
                    _buildMiniChip(
                      Icons.arrow_upward_rounded,
                      '${torrent.seeders} seeds',
                      colorScheme,
                      isHighlight: true,
                    ),
                  ],
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      String? magnet = torrent.magnet;
                      if (magnet == null && torrent.detailUrl != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fetching magnet...'),
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                        magnet = await _torrentSomeService.fetchMagnet(
                          torrent.detailUrl!,
                        );
                      }
                      if (magnet != null) {
                        Clipboard.setData(ClipboardData(text: magnet));
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Magnet copied!')),
                          );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add_rounded),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _addToSeedr(torrent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.1);
  }

  Widget _buildMiniChip(
    IconData icon,
    String label,
    ColorScheme colorScheme, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? Colors.green.withOpacity(0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? Colors.green.withOpacity(0.2)
              : colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isHighlight ? Colors.green : colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.green : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.secondaryContainer.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabHeader extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabHeader(this.tabBar, this.backgroundColor);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
