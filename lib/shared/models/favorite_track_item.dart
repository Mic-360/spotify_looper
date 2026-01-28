import 'playback_mode.dart';
import 'track.dart';

class FavoriteTrackItem {
  final Track track;
  final PlaybackMode mode;
  final SectionMarker? section;
  final String likes;
  final int loopCount;
  final String? curator;

  const FavoriteTrackItem({
    required this.track,
    required this.mode,
    this.section,
    this.likes = '0',
    this.loopCount = 0,
    this.curator,
  });
}
