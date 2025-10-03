/// Represents a single Carnatic music note with modifiers
class Note {
  String swara; // S, R, G, M, P, D, N, or separator |, ||
  bool hasUpperDot; // Tara sthayi (upper octave)
  bool hasLowerDot; // Mandra sthayi (lower octave)
  bool hasUnderline; // Grouping indicator
  bool hasOverline; // Grouping indicator

  Note({
    required this.swara,
    this.hasUpperDot = false,
    this.hasLowerDot = false,
    this.hasUnderline = false,
    this.hasOverline = false,
  });

  /// Create a separator (| or ||)
  Note.separator(String separator)
      : swara = separator,
        hasUpperDot = false,
        hasLowerDot = false,
        hasUnderline = false,
        hasOverline = false;

  /// Create a copy with modifications
  Note copyWith({
    String? swara,
    bool? hasUpperDot,
    bool? hasLowerDot,
    bool? hasUnderline,
    bool? hasOverline,
  }) {
    return Note(
      swara: swara ?? this.swara,
      hasUpperDot: hasUpperDot ?? this.hasUpperDot,
      hasLowerDot: hasLowerDot ?? this.hasLowerDot,
      hasUnderline: hasUnderline ?? this.hasUnderline,
      hasOverline: hasOverline ?? this.hasOverline,
    );
  }

  bool get isSeparator => swara == '|' || swara == '||';

  Map<String, dynamic> toJson() {
    return {
      'swara': swara,
      'hasUpperDot': hasUpperDot,
      'hasLowerDot': hasLowerDot,
      'hasUnderline': hasUnderline,
      'hasOverline': hasOverline,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      swara: json['swara'] as String,
      hasUpperDot: json['hasUpperDot'] as bool? ?? false,
      hasLowerDot: json['hasLowerDot'] as bool? ?? false,
      hasUnderline: json['hasUnderline'] as bool? ?? false,
      hasOverline: json['hasOverline'] as bool? ?? false,
    );
  }
}
