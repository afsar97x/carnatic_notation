/// Represents a swara (note) in Carnatic music with octave information
class Swara {
  final SwaraNote note;
  final Octave octave;

  const Swara({
    required this.note,
    this.octave = Octave.middle,
  });

  /// Display string for the swara with octave markers
  String get display {
    switch (octave) {
      case Octave.lower:
        return '${note.symbol}̣'; // Dot below
      case Octave.middle:
        return note.symbol;
      case Octave.upper:
        return '${note.symbol}̇'; // Dot above
    }
  }

  /// Plain text representation (for editing)
  String get plainText {
    switch (octave) {
      case Octave.lower:
        return '${note.symbol}_';
      case Octave.middle:
        return note.symbol;
      case Octave.upper:
        return '${note.symbol}.';
    }
  }

  /// Parse a swara from plain text (e.g., "S", "S.", "S_")
  static Swara? parse(String text) {
    if (text.isEmpty) return null;

    final note = SwaraNote.fromSymbol(text[0]);
    if (note == null) return null;

    Octave octave = Octave.middle;
    if (text.length > 1) {
      if (text[1] == '.') {
        octave = Octave.upper;
      } else if (text[1] == '_') {
        octave = Octave.lower;
      }
    }

    return Swara(note: note, octave: octave);
  }

  /// Cycle to next octave (for multi-tap input)
  Swara cycleOctave() {
    final nextOctave = switch (octave) {
      Octave.middle => Octave.upper,
      Octave.upper => Octave.lower,
      Octave.lower => Octave.middle,
    };
    return Swara(note: note, octave: nextOctave);
  }

  @override
  String toString() => display;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Swara &&
          runtimeType == other.runtimeType &&
          note == other.note &&
          octave == other.octave;

  @override
  int get hashCode => note.hashCode ^ octave.hashCode;

  Map<String, dynamic> toJson() => {
        'note': note.symbol,
        'octave': octave.index,
      };

  factory Swara.fromJson(Map<String, dynamic> json) => Swara(
        note: SwaraNote.fromSymbol(json['note'])!,
        octave: Octave.values[json['octave']],
      );
}

/// The seven swaras in Carnatic music
enum SwaraNote {
  sa('S', 'Shadjam'),
  ri('R', 'Rishabham'),
  ga('G', 'Gandharam'),
  ma('M', 'Madhyamam'),
  pa('P', 'Panchamam'),
  dha('D', 'Dhaivatam'),
  ni('N', 'Nishadam');

  final String symbol;
  final String name;

  const SwaraNote(this.symbol, this.name);

  static SwaraNote? fromSymbol(String symbol) {
    try {
      return SwaraNote.values.firstWhere(
        (note) => note.symbol.toLowerCase() == symbol.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Octave variations for swaras
enum Octave {
  lower, // Mandra (dot below)
  middle, // Madhya (no marker)
  upper, // Tara (dot above)
}
