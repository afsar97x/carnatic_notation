import 'package:flutter/material.dart';
import '../models/notation_segment.dart';
import '../models/note.dart';
import 'note_display.dart';

/// Widget to display and edit a notation segment (notes + syllables)
class SegmentEditor extends StatelessWidget {
  final NotationSegment segment;
  final int? selectedNoteIndex;
  final Function(int)? onNoteTap;

  const SegmentEditor({
    Key? key,
    required this.segment,
    this.selectedNoteIndex,
    this.onNoteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes row
          Wrap(
            spacing: 4,
            children: segment.notes.asMap().entries.map((entry) {
              int idx = entry.key;
              Note note = entry.value;
              return NoteDisplay(
                note: note,
                isSelected: selectedNoteIndex == idx,
                onTap: () => onNoteTap?.call(idx),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Syllables row
          Wrap(
            spacing: 8,
            children: segment.syllables.map((syllable) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  syllable,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
