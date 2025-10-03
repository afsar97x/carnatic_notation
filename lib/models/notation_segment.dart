import 'note.dart';

/// Represents a segment: one or more notes aligned with one or more syllables
class NotationSegment {
  List<Note> notes;
  List<String> syllables;

  NotationSegment({
    required this.notes,
    required this.syllables,
  });

  /// Create an empty segment
  NotationSegment.empty()
      : notes = [],
        syllables = [];

  Map<String, dynamic> toJson() {
    return {
      'notes': notes.map((n) => n.toJson()).toList(),
      'syllables': syllables,
    };
  }

  factory NotationSegment.fromJson(Map<String, dynamic> json) {
    return NotationSegment(
      notes: (json['notes'] as List)
          .map((n) => Note.fromJson(n as Map<String, dynamic>))
          .toList(),
      syllables: List<String>.from(json['syllables'] as List),
    );
  }
}
