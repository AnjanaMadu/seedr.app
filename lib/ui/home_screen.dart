import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../service/seedr.dart';
import '../service/settings_service.dart';
import '../models/seedr_models.dart';
import 'log_screen.dart';
import 'add_magnet_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  SeedrFolderResponse? _currentFolder;
  Timer? _refreshTimer;
  final List<int?> _navigationStack = [null]; // null is root

  @override
  void initState() {
    super.initState();
    _fetchContents();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isLoading) {
        _fetchContents(silent: true);
      }
    });
  }

  Future<void> _fetchContents({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final seedr = context.read<Seedr>();
      final contents = await seedr.getFolderContents(_navigationStack.last);
      if (mounted) {
        setState(() => _currentFolder = contents);
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to fetch contents: $e')));
      }
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  void _navigateToFolder(int id) {
    setState(() {
      _navigationStack.add(id);
    });
    _fetchContents();
  }

  bool _onWillPop() {
    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
      });
      _fetchContents();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsService>();

    return PopScope(
      canPop: _navigationStack.length <= 1,
      onPopInvoked: (didPop) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text(
                _currentFolder?.name.isEmpty ?? true
                    ? 'My Seedr files'
                    : _currentFolder!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    settings.themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: () {
                    settings.setThemeMode(
                      settings.themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LogScreen())),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => settings.logout(),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_currentFolder != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildQuotaBar(colorScheme),
                ),
              ),
            SliverFillRemaining(
              child: RefreshIndicator(
                onRefresh: _fetchContents,
                child: _isLoading
                    ? _buildShimmer(colorScheme)
                    : _buildContent(colorScheme),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddMagnetDialog(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Magnet'),
        ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildQuotaBar(ColorScheme colorScheme) {
    if (_currentFolder == null) return const SizedBox.shrink();

    final used = _currentFolder!.spaceUsed;
    final max = _currentFolder!.spaceMax;
    final progress = max > 0 ? used / max : 0.0;

    final usedGB = (used / (1024 * 1024 * 1024)).toStringAsFixed(2);
    final maxGB = (max / (1024 * 1024 * 1024)).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Storage Usage',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '$usedGB GB / $maxGB GB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.9 ? colorScheme.error : colorScheme.primary,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildShimmer(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: colorScheme.surfaceVariant.withOpacity(0.5),
        highlightColor: colorScheme.surface,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(height: 80, width: double.infinity),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    if (_currentFolder == null) return const SizedBox.shrink();

    final folders = _currentFolder!.folders;
    final files = _currentFolder!.files;
    final torrents = _currentFolder!.torrents;

    if (folders.isEmpty && files.isEmpty && torrents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'This folder is empty',
              style: TextStyle(color: colorScheme.outline),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        if (torrents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Active Torrents',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          ...torrents.map((torrent) => _buildTorrentTile(torrent, colorScheme)),
          const Divider(),
        ],
        ...folders.map((folder) => _buildFolderTile(folder, colorScheme)),
        ...files.map((file) => _buildFileTile(file, colorScheme)),
      ],
    );
  }

  Widget _buildTorrentTile(SeedrTorrent torrent, ColorScheme colorScheme) {
    final progress = double.tryParse(torrent.progress) ?? 0.0;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress / 100,
                backgroundColor: colorScheme.surfaceVariant,
                strokeWidth: 4,
              ),
              Icon(
                Icons.download_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
        title: Text(
          torrent.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_formatSize(torrent.size)),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.cancel_outlined),
          onPressed: () => _confirmDeleteTorrent(torrent),
          color: colorScheme.error,
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Future<void> _confirmDeleteTorrent(SeedrTorrent torrent) async {
    final confirm = await _showDeleteDialog(
      'Remove Torrent',
      'Are you sure you want to remove torrent "${torrent.name}"?',
    );
    if (confirm == true) {
      try {
        await context.read<Seedr>().deleteTorrent(torrent.id.toString());
        _fetchContents();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
        }
      }
    }
  }

  Widget _buildFolderTile(SeedrFolder folder, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Icon(Icons.folder_rounded, color: colorScheme.primary),
        title: Text(
          folder.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatSize(folder.size)),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text('Create Archive'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'archive') {
              _createArchive(folder);
            } else if (value == 'delete') {
              _confirmDeleteFolder(folder);
            }
          },
        ),
        onTap: () => _navigateToFolder(folder.id),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildFileTile(SeedrFile file, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          file.playVideo
              ? Icons.movie_rounded
              : Icons.insert_drive_file_rounded,
          color: colorScheme.secondary,
        ),
        title: Text(file.name),
        subtitle: Text(_formatSize(file.size)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _confirmDeleteFile(file),
        ),
        onTap: () => _playFile(file),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.toString().length - 1) ~/ 3;
    var res = bytes / (1 << (i * 10));
    return '${res.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _playFile(SeedrFile file) async {
    try {
      final details = await context.read<Seedr>().getFile(file.folderFileId);
      if (details.result) {
        await Clipboard.setData(ClipboardData(text: details.url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Direct link copied to clipboard!')),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting link: $e')));
    }
  }

  void _showAddMagnetDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddMagnetDialog(),
    ).then((value) {
      if (value == true) _fetchContents();
    });
  }

  Future<void> _createArchive(SeedrFolder folder) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Creating archive...')));
      }
      final details = await context.read<Seedr>().createArchive(
        folder.id.toString(),
      );
      if (details.result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Archive created! Copy link from logs: ${details.archiveUrl.substring(0, 30)}...',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create archive.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating archive: $e')));
      }
    }
  }

  Future<void> _confirmDeleteFile(SeedrFile file) async {
    final confirm = await _showDeleteDialog(
      'Delete File',
      'Are you sure you want to delete "${file.name}"?',
    );
    if (confirm == true) {
      try {
        await context.read<Seedr>().deleteFile(file.folderFileId.toString());
        _fetchContents();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _confirmDeleteFolder(SeedrFolder folder) async {
    final confirm = await _showDeleteDialog(
      'Delete Folder',
      'Are you sure you want to delete folder "${folder.name}" and all its contents?',
    );
    if (confirm == true) {
      try {
        await context.read<Seedr>().deleteFolder(folder.id.toString());
        _fetchContents();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<bool?> _showDeleteDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
