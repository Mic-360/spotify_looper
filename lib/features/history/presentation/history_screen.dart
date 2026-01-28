import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/spacing.dart';
import '../../../shared/models/track.dart';

class HistoryEntry {
  final Track track;
  final DateTime playedAt;

  const HistoryEntry({required this.track, required this.playedAt});
}

/// History screen with grouped tracks and high-fidelity Pulse Loop aesthetic.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _GlowBlob extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color color;
  final double size;

  const _GlowBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
          ],
        ),
      ),
    );
  }
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<HistoryEntry> _todayHistory = [];
  List<HistoryEntry> _yesterdayHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          _buildBackgroundGlows(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    Spacing.l,
                    Spacing.l,
                    Spacing.m,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Playback History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DB954),
                          ),
                        )
                      : _todayHistory.isEmpty && _yesterdayHistory.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.xl,
                          ),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Today Section
                            if (_todayHistory.isNotEmpty) ...[
                              const _SectionHeader(title: 'Today'),
                              const SizedBox(height: 12),
                              // Now Playing / First Item
                              _NowPlayingTile(
                                entry: _todayHistory.first,
                                onTap: () => context.go(
                                  '/player/${_todayHistory.first.track.id}',
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Remaining Today
                              ..._todayHistory
                                  .skip(1)
                                  .map(
                                    (entry) => _HistoryTile(
                                      entry: entry,
                                      timeLabel: _formatTimeLabel(
                                        entry.playedAt,
                                      ),
                                      onTap: () => context.go(
                                        '/player/${entry.track.id}',
                                      ),
                                    ),
                                  ),
                            ],

                            // Yesterday Section
                            if (_yesterdayHistory.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const _SectionHeader(title: 'Yesterday'),
                              const SizedBox(height: 12),
                              ..._yesterdayHistory.map(
                                (entry) => _HistoryTile(
                                  entry: entry,
                                  timeLabel: _formatTimeLabel(entry.playedAt),
                                  onTap: () =>
                                      context.go('/player/${entry.track.id}'),
                                ),
                              ),
                            ],

                            const SizedBox(height: 100), // Navigation padding
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Widget _buildBackgroundGlows() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: const Color(0xFF0F0F0F)),
          _GlowBlob(
            top: -100,
            right: -100,
            color: Colors.purple.withValues(alpha: 0.12),
            size: 400,
          ),
          _GlowBlob(
            bottom: 150,
            left: -150,
            color: Colors.blue.withValues(alpha: 0.08),
            size: 350,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.white10),
          SizedBox(height: Spacing.m),
          Text('No history yet.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatTimeLabel(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} AM';
  }

  Future<void> _loadHistory() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _isLoading = false;
        _todayHistory = List.generate(
          4,
          (index) => HistoryEntry(
            track: Track(
              id: 'today_$index',
              name: [
                'Midnight City',
                'Heat Waves',
                'As It Was',
                'Blinding Lights',
              ][index],
              artistName: [
                'M83',
                'Glass Animals',
                'Harry Styles',
                'The Weeknd',
              ][index],
              albumName: [
                'Hurry Up, We\'re Dreaming',
                'Dreamland',
                'Harry\'s House',
                'After Hours',
              ][index],
              albumCoverUrl: 'https://picsum.photos/seed/hist_t$index/200/200',
              duration: const Duration(minutes: 3, seconds: 45),
              spotifyUri: 'spotify:track:hist_t$index',
            ),
            playedAt: now.subtract(Duration(minutes: index * 45)),
          ),
        );

        _yesterdayHistory = List.generate(
          4,
          (index) => HistoryEntry(
            track: Track(
              id: 'yest_$index',
              name: [
                'Stay',
                'Good 4 U',
                'Levitating',
                'Save Your Tears',
              ][index],
              artistName: [
                'The Kid LAROI, Justin Bieber',
                'Olivia Rodrigo',
                'Dua Lipa',
                'The Weeknd',
              ][index],
              albumName: [
                'F*CK LOVE 3',
                'SOUR',
                'Future Nostalgia',
                'After Hours',
              ][index],
              albumCoverUrl: 'https://picsum.photos/seed/hist_y$index/200/200',
              duration: const Duration(minutes: 3, seconds: 15),
              spotifyUri: 'spotify:track:hist_y$index',
            ),
            playedAt: now.subtract(Duration(days: 1, hours: index * 2)),
          ),
        );
      });
    }
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final String timeLabel;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.entry,
    required this.timeLabel,
    required this.onTap,
  });

  // Note: index is not available here, I should probably pass it or just mock it.
  // The HTML has some favorited and some not. I'll just use a bool or random logic.
  int get index => entry.track.id.hashCode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                entry.track.albumCoverUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.track.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.track.artistName} • ${entry.track.albumName}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              index % 3 == 0
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: index % 3 == 0 ? const Color(0xFF1DB954) : Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingTile extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;

  const _NowPlayingTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD7E3F8).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    entry.track.albumCoverUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.equalizer_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.track.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(
                        'Now',
                        style: TextStyle(
                          color: Color(0xFF1DB954),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.track.artistName} • ${entry.track.albumName}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF1DB954),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}
