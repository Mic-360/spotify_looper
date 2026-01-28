import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';
import '../../../shared/models/track.dart';
import '../../../shared/widgets/loading_indicator.dart';

class HistoryEntry {
  final Track track;
  final DateTime playedAt;

  const HistoryEntry({required this.track, required this.playedAt});
}

/// History screen showing recently played tracks.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryListItem extends StatelessWidget {
  final HistoryEntry entry;
  final String timeAgo;
  final VoidCallback? onTap;

  const _HistoryListItem({
    required this.entry,
    required this.timeAgo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.s),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: entry.track.albumCoverUrl.isNotEmpty
                ? Image.network(
                    entry.track.albumCoverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _albumPlaceholder(colorScheme),
                  )
                : _albumPlaceholder(colorScheme),
          ),
        ),
        title: Text(
          entry.track.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          entry.track.artistName,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          timeAgo,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _albumPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<HistoryEntry> _history = [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _history.isEmpty ? null : _clearHistory,
            tooltip: 'Clear history',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingOverlay(message: 'Loading history...')
          : _history.isEmpty
          ? _buildEmptyState(colorScheme, textTheme)
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final entry = _history[index];
                  return _HistoryListItem(
                    entry: entry,
                    timeAgo: _formatTimeAgo(entry.playedAt),
                    onTap: () => context.go('/player/${entry.track.id}'),
                  );
                },
              ),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: Spacing.l),
          Text('No listening history', style: textTheme.titleLarge),
          const SizedBox(height: Spacing.s),
          Text(
            'Start playing tracks to see them here',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text(
          'Are you sure you want to clear your listening history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _history.clear());
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  List<HistoryEntry> _getMockHistory() {
    final now = DateTime.now();
    return List.generate(20, (index) {
      return HistoryEntry(
        track: Track(
          id: 'history_$index',
          name: 'Track ${index + 1}',
          artistName: 'Artist ${(index % 5) + 1}',
          albumName: 'Album ${(index % 3) + 1}',
          albumCoverUrl: 'https://picsum.photos/seed/history$index/300/300',
          duration: Duration(minutes: 3 + (index % 3), seconds: 15 + index),
          spotifyUri: 'spotify:track:history_$index',
        ),
        playedAt: now.subtract(Duration(hours: index * 2, minutes: index * 5)),
      );
    });
  }

  Future<void> _loadHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _history = _getMockHistory();
      });
    }
  }
}
