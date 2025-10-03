import 'notation_segment.dart';

/// Represents a complete Carnatic song with notation
class Song {
  String id;
  String title;
  String? raga;
  String? tala;
  String? composer;
  List<NotationSegment> segments;
  DateTime createdAt;
  DateTime updatedAt;

  Song({
    required this.id,
    required this.title,
    this.raga,
    this.tala,
    this.composer,
    required this.segments,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new empty song
  Song.create({required this.title})
      : id = DateTime.now().millisecondsSinceEpoch.toString(),
        raga = null,
        tala = null,
        composer = null,
        segments = [],
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'raga': raga,
      'tala': tala,
      'composer': composer,
      'segments': segments.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      raga: json['raga'] as String?,
      tala: json['tala'] as String?,
      composer: json['composer'] as String?,
      segments: (json['segments'] as List)
          .map((s) => NotationSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
