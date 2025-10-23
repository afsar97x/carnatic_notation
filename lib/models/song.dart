import 'notation_segment.dart';

/// Represents a complete song with lyrics and notation
class Song {
  final String id;
  final String title;
  final String lyrics;
  final List<NotationSegment> segments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId; // Owner of the song (for local app, always 'local')

  Song({
    required this.id,
    required this.title,
    required this.lyrics,
    required this.segments,
    required this.createdAt,
    required this.updatedAt,
    this.userId = 'local',
  });

  /// Create an empty song
  factory Song.empty([String userId = 'local']) {
    final now = DateTime.now();
    // Generate a unique ID based on timestamp
    final id = 'song_${now.millisecondsSinceEpoch}';
    return Song(
      id: id,
      title: 'Untitled Song',
      lyrics: '',
      segments: [],
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
  }

  /// Get all segments that overlap with a text range
  List<NotationSegment> getSegmentsInRange(int start, int end) {
    return segments.where((seg) => seg.overlapsWith(start, end)).toList();
  }

  /// Get segment at a specific index
  NotationSegment? getSegmentAt(int index) {
    try {
      return segments.firstWhere((seg) => seg.contains(index));
    } catch (e) {
      return null;
    }
  }

  /// Check if a text range has any notation
  bool hasNotationInRange(int start, int end) {
    return segments.any((seg) => seg.overlapsWith(start, end));
  }

  Song copyWith({
    String? id,
    String? title,
    String? lyrics,
    List<NotationSegment>? segments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      lyrics: lyrics ?? this.lyrics,
      segments: segments ?? this.segments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'lyrics': lyrics,
        'segments': segments.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'userId': userId,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'],
        title: json['title'],
        lyrics: json['lyrics'],
        segments: (json['segments'] as List)
            .map((s) => NotationSegment.fromJson(s))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        userId: json['userId'] ?? 'local',
      );

  @override
  String toString() => 'Song($title)';
}
