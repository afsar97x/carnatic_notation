import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notation_segment.dart';

class LineByLineEditor extends StatefulWidget {
  final List<String> initialLines;
  final List<NotationSegment> segments;
  final Function(List<String> lines) onLinesChanged;
  final Function(int lineIndex, int start, int end) onTextSelected;

  const LineByLineEditor({
    super.key,
    required this.initialLines,
    required this.segments,
    required this.onLinesChanged,
    required this.onTextSelected,
  });

  @override
  State<LineByLineEditor> createState() => _LineByLineEditorState();
}

class _LineByLineEditorState extends State<LineByLineEditor> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  int? _selectedLineIndex;
  TextSelection? _currentSelection;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Start with at least 3 lyric lines
    final lines = widget.initialLines.isNotEmpty
        ? widget.initialLines
        : ['', '', ''];

    _controllers = lines.map((line) => TextEditingController(text: line)).toList();
    _focusNodes = List.generate(lines.length, (_) => FocusNode());

    // Add listeners to each controller
    for (int i = 0; i < _controllers.length; i++) {
      final controller = _controllers[i];
      final index = i;
      controller.addListener(() {
        _onTextChanged(index);
      });
    }

    // Add listeners to focus nodes
    for (int i = 0; i < _focusNodes.length; i++) {
      final focusNode = _focusNodes[i];
      final index = i;
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          setState(() => _selectedLineIndex = index);
        } else {
          // When focus is lost, notify parent that selection is cleared
          widget.onTextSelected(index, 0, 0);
        }
      });
    }
  }

  void _onTextChanged(int lineIndex) {
    final selection = _controllers[lineIndex].selection;

    setState(() {
      _selectedLineIndex = lineIndex;
      _currentSelection = selection;
    });

    // Always notify parent about selection changes (including when cleared)
    widget.onTextSelected(lineIndex, selection.start, selection.end);

    // Notify parent of line changes
    widget.onLinesChanged(_controllers.map((c) => c.text).toList());
  }

  String _getNotationForLine(int lineIndex) {
    // Get all segments for this line
    final lineSegments = widget.segments.where((seg) {
      // Segments store global indices, we need to map to line indices
      return _isSegmentInLine(seg, lineIndex);
    }).toList();

    if (lineSegments.isEmpty) return '';

    return lineSegments.map((seg) => seg.swarasDisplay).join(' ');
  }

  bool _isSegmentInLine(NotationSegment segment, int lineIndex) {
    // Calculate the line's character range in the overall text
    int currentPos = 0;
    for (int i = 0; i < lineIndex; i++) {
      currentPos += _controllers[i].text.length + 1; // +1 for newline
    }
    final lineStart = currentPos;
    final lineEnd = currentPos + _controllers[lineIndex].text.length;

    return segment.startIndex >= lineStart && segment.endIndex <= lineEnd;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _controllers.length,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notation line (read-only, above lyrics)
              _buildNotationLine(index),
              const SizedBox(height: 8),
              // Lyrics line (editable)
              _buildLyricsLine(index),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotationLine(int index) {
    final notation = _getNotationForLine(index);
    final isSelected = _selectedLineIndex == index && _currentSelection != null &&
                       _currentSelection!.start != _currentSelection!.end;

    // If this lyrics line is selected, show a text input in the notation line above
    if (isSelected) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.music_note_rounded,
              color: Color(0xFFFF6B35),
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                autofocus: true,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Add notation...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    // Parse and save notation
                    _saveNotation(index, value);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    // Otherwise show the notation display
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: notation.isNotEmpty
            ? const Color(0xFFFF6B35).withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: notation.isNotEmpty
              ? const Color(0xFFFF6B35).withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        notation.isNotEmpty ? notation : '─',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: notation.isNotEmpty
              ? const Color(0xFFFF6B35)
              : Colors.white.withOpacity(0.2),
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _saveNotation(int lineIndex, String input) {
    final selection = _controllers[lineIndex].selection;
    widget.onTextSelected(lineIndex, selection.start, selection.end);
    // The parent will handle saving via the floating toolbar method
    // For now, just clear the selection to hide the input
    setState(() {
      _selectedLineIndex = null;
      _currentSelection = null;
    });
  }

  Widget _buildLyricsLine(int index) {
    return TextField(
      controller: _controllers[index],
      focusNode: _focusNodes[index],
      maxLines: 1,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) {
        // When Enter is pressed, add a new line if this is the last one
        if (index == _controllers.length - 1) {
          setState(() {
            _controllers.add(TextEditingController());
            _focusNodes.add(FocusNode());

            // Add listeners to the new controller and focus node
            final newIndex = _controllers.length - 1;
            _controllers[newIndex].addListener(() {
              _onTextChanged(newIndex);
            });
            _focusNodes[newIndex].addListener(() {
              if (_focusNodes[newIndex].hasFocus) {
                setState(() => _selectedLineIndex = newIndex);
              } else {
                widget.onTextSelected(newIndex, 0, 0);
              }
            });
          });

          // Notify parent of the new line
          widget.onLinesChanged(_controllers.map((c) => c.text).toList());

          // Focus on the new line after a brief delay
          Future.delayed(const Duration(milliseconds: 50), () {
            if (_focusNodes.length > index + 1) {
              _focusNodes[index + 1].requestFocus();
            }
          });
        } else {
          // Move to next line
          _focusNodes[index + 1].requestFocus();
        }
      },
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.white,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: 'Type lyrics for line ${index + 1}...',
        hintStyle: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.3),
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFFF6B35),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
