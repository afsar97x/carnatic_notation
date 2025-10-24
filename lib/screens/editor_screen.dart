import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/song.dart';
import '../models/notation_segment.dart';
import '../models/swara.dart';
import '../services/local_storage_service.dart';
import '../widgets/swara_keyboard.dart';
import '../widgets/line_by_line_editor.dart';

class EditorScreen extends StatefulWidget {
  final Song song;

  const EditorScreen({super.key, required this.song});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _lyricsController;
  late TextEditingController _notationController;
  late List<NotationSegment> _segments;
  bool _isSaving = false;

  // Text selection tracking
  TextSelection _currentSelection = const TextSelection.collapsed(offset: 0);
  bool _showFloatingToolbar = false;
  Offset _toolbarPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _lyricsController = TextEditingController(text: widget.song.lyrics);
    _notationController = TextEditingController();
    _segments = List.from(widget.song.segments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    _notationController.dispose();
    super.dispose();
  }

  void _onLinesChanged(List<String> lines) {
    // Update lyrics from line-by-line editor
    setState(() {
      _lyricsController.text = lines.join('\n');
    });
  }

  void _onTextSelected(int lineIndex, int start, int end) {
    // Calculate global position from line-based position
    int globalStart = 0;
    for (int i = 0; i < lineIndex; i++) {
      globalStart += _lyricsController.text.split('\n')[i].length + 1;
    }
    globalStart += start;
    final globalEnd = globalStart + (end - start);

    setState(() {
      _currentSelection = TextSelection(baseOffset: globalStart, extentOffset: globalEnd);
      // Only show toolbar if there's actually a selection
      _showFloatingToolbar = start != end;
    });
  }

  void _saveNotationFromInput(String input) {
    if (input.trim().isEmpty) {
      setState(() => _showFloatingToolbar = false);
      _notationController.clear();
      return;
    }

    // Parse swaras from input (e.g., "S R G M" or "S. R G_ M")
    final swaraTexts = input.trim().split(RegExp(r'\s+'));
    final swaras = <Swara>[];

    for (final text in swaraTexts) {
      final swara = Swara.parse(text);
      if (swara != null) {
        swaras.add(swara);
      }
    }

    if (swaras.isEmpty) {
      _showSnackBar('Invalid swara notation', isError: true);
      return;
    }

    final start = _currentSelection.start;
    final end = _currentSelection.end;

    setState(() {
      // Remove any overlapping segments
      _segments.removeWhere((seg) => seg.overlapsWith(start, end));

      // Add new segment
      _segments.add(NotationSegment(
        id: const Uuid().v4(),
        startIndex: start,
        endIndex: end,
        swaras: swaras,
      ));

      // Sort segments by position
      _segments.sort((a, b) => a.startIndex.compareTo(b.startIndex));

      // Clear and hide toolbar
      _showFloatingToolbar = false;
      _notationController.clear();
    });

    _showSnackBar('Notation added successfully!', isError: false);
  }

  Future<void> _saveSong() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a song title', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedSong = widget.song.copyWith(
        title: _titleController.text.trim(),
        lyrics: _lyricsController.text,
        segments: _segments,
        updatedAt: DateTime.now(),
      );

      final localStorage = context.read<LocalStorageService>();
      if (updatedSong.id.isEmpty || updatedSong.id.startsWith('song_')) {
        await localStorage.createSong(updatedSong);
      } else {
        await localStorage.updateSong(updatedSong);
      }

      if (mounted) {
        _showSnackBar('Song saved successfully!', isError: false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving song: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFE63946)
            : const Color(0xFF06D6A0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _addNotationToSelection() {
    if (_currentSelection.start == _currentSelection.end) return;

    final start = _currentSelection.start;
    final end = _currentSelection.end;

    // Find existing segment for this selection
    final existingSegment = _segments.where((seg) {
      return seg.startIndex == start && seg.endIndex == end;
    }).firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SwaraKeyboard(
          initialSwaras: existingSegment?.swaras ?? [],
          onSwarasChanged: (swaras) {
            setState(() {
              _segments.removeWhere((seg) => seg.overlapsWith(start, end));

              if (swaras.isNotEmpty) {
                _segments.add(NotationSegment(
                  id: const Uuid().v4(),
                  startIndex: start,
                  endIndex: end,
                  swaras: swaras,
                ));
              }

              _segments.sort((a, b) => a.startIndex.compareTo(b.startIndex));
              _showFloatingToolbar = false;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Custom AppBar
                  _buildCustomAppBar(),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Field
                          _buildTitleField(),

                          const SizedBox(height: 24),

                          // Lyrics Section Header
                          _buildLyricsHeader(),

                          const SizedBox(height: 12),

                          // Lyrics Editor with inline notation
                          _buildLyricsEditor(),

                          const SizedBox(height: 24),

                          // Show notations if any exist
                          if (_segments.isNotEmpty) _buildNotationsPreview(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating toolbar for text selection
              if (_showFloatingToolbar) _buildFloatingToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingToolbar() {
    return Positioned(
      left: 40,
      right: 40,
      top: 260,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _notationController,
                autofocus: true,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Add Note',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (value) {
                  _saveNotationFromInput(value);
                },
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ).animate().fadeIn().scale(),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Song Editor',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2, end: 0),
          ),

          // Save Button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFF7931E),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save_rounded, color: Colors.white),
              onPressed: _isSaving ? null : _saveSong,
              tooltip: 'Save Song',
            ),
          ).animate().fadeIn(delay: 200.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
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
      child: TextField(
        controller: _titleController,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Song Title',
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.4),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.title_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildLyricsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.lyrics_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Lyrics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6B35).withOpacity(0.3),
                const Color(0xFFF7931E).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFF6B35).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: Color(0xFFFF6B35),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Select text',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fadeIn(duration: 1500.ms),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildLyricsEditor() {
    final lines = _lyricsController.text.isEmpty
        ? <String>[]
        : _lyricsController.text.split('\n');

    return LineByLineEditor(
      initialLines: lines,
      segments: _segments,
      onLinesChanged: _onLinesChanged,
      onTextSelected: _onTextSelected,
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNotationsPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.library_music_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Notations (${_segments.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _segments.map((segment) {
              final text = _lyricsController.text.substring(
                segment.startIndex,
                segment.endIndex,
              );
              return _buildNotationChip(text, segment);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotationChip(String text, NotationSegment segment) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _segments.removeWhere((s) => s.id == segment.id);
        });
        _showSnackBar('Notation removed', isError: false);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFF7931E),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              segment.swarasDisplay,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
