import 'swara.dart';

/// Represents a mapping between a text segment and its swaras
/// Handles the N-to-M relationship between lyrics and notation
class NotationSegment {
  final String id;
  final int startIndex; // Start position in the lyrics text
  final int endIndex; // End position in the lyrics text (exclusive)
  final List<Swara> swaras; // The swaras for this text segment

  NotationSegment({
    required this.id,
    required this.startIndex,
    required this.endIndex,
    required this.swaras,
  });

  /// The text length of this segment
  int get length => endIndex - startIndex;

  /// Check if this segment overlaps with another
  bool overlapsWith(int start, int end) {
    return !(end <= startIndex || start >= endIndex);
  }

  /// Check if this segment contains a specific index
  bool contains(int index) {
    return index >= startIndex && index < endIndex;
  }

  /// Get the display string for swaras
  String get swarasDisplay => swaras.map((s) => s.display).join(' ');

  /// Get plain text representation of swaras
  String get swarasPlainText => swaras.map((s) => s.plainText).join(' ');

  NotationSegment copyWith({
    String? id,
    int? startIndex,
    int? endIndex,
    List<Swara>? swaras,
  }) {
    return NotationSegment(
      id: id ?? this.id,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      swaras: swaras ?? this.swaras,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startIndex': startIndex,
        'endIndex': endIndex,
        'swaras': swaras.map((s) => s.toJson()).toList(),
      };

  factory NotationSegment.fromJson(Map<String, dynamic> json) =>
      NotationSegment(
        id: json['id'],
        startIndex: json['startIndex'],
        endIndex: json['endIndex'],
        swaras: (json['swaras'] as List)
            .map((s) => Swara.fromJson(s))
            .toList(),
      );

  @override
  String toString() =>
      'NotationSegment($startIndex-$endIndex: $swarasDisplay)';
}
