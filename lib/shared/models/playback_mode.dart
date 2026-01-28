/// Playback mode enum for Normal, Loop, and Skip modes.
enum PlaybackMode {
  /// Standard playback
  normal,

  /// Loop selected section
  loop,

  /// Skip selected section
  skip;

  String get description {
    switch (this) {
      case PlaybackMode.normal:
        return 'Standard playback';
      case PlaybackMode.loop:
        return 'Loop selected section';
      case PlaybackMode.skip:
        return 'Skip selected section';
    }
  }

  String get displayName {
    switch (this) {
      case PlaybackMode.normal:
        return 'Normal';
      case PlaybackMode.loop:
        return 'Loop';
      case PlaybackMode.skip:
        return 'Skip';
    }
  }
}

/// Section marker for loop/skip functionality.
class SectionMarker {
  final Duration startTime;
  final Duration endTime;
  final String? label;

  const SectionMarker({
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory SectionMarker.fromJson(Map<String, dynamic> json) {
    return SectionMarker(
      startTime: Duration(milliseconds: json['startTime'] as int? ?? 0),
      endTime: Duration(milliseconds: json['endTime'] as int? ?? 0),
      label: json['label'] as String?,
    );
  }

  /// Duration of the section
  Duration get duration => endTime - startTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionMarker &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  /// Check if a position is within this section
  bool contains(Duration position) {
    return position >= startTime && position <= endTime;
  }

  SectionMarker copyWith({
    Duration? startTime,
    Duration? endTime,
    String? label,
  }) {
    return SectionMarker(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime.inMilliseconds,
    'endTime': endTime.inMilliseconds,
    'label': label,
  };
}
