import 'package:flutter/material.dart';
import '../models/note.dart';

/// Widget to display a single note with all modifiers (dots, underlines, etc.)
class NoteDisplay extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback? onTap;
  final double fontSize;

  const NoteDisplay({
    Key? key,
    required this.note,
    this.isSelected = false,
    this.onTap,
    this.fontSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upper dot
            SizedBox(
              height: 10,
              child: note.hasUpperDot
                  ? Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            // Overline
            if (note.hasOverline)
              Container(
                width: fontSize + 8,
                height: 2,
                color: Colors.black,
                margin: const EdgeInsets.only(bottom: 2),
              ),
            // The note itself
            Text(
              note.swara,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                decoration: note.hasUnderline
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationThickness: 2,
              ),
            ),
            // Lower dot
            SizedBox(
              height: 10,
              child: note.hasLowerDot
                  ? Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
