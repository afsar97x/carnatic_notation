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

class EditorScreen extends StatefulWidget {
  final Song song;

  const EditorScreen({super.key, required this.song});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _lyricsController;
  late List<NotationSegment> _segments;
  bool _isEditMode = false;
  int? _selectionStart;
  int? _selectionEnd;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _lyricsController = TextEditingController(text: widget.song.lyrics);
    _segments = List.from(widget.song.segments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    super.dispose();
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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  void _showSwaraKeyboard(int start, int end) {
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
          child: Column(
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

                      // Lyrics Editor/Display
                      if (_isEditMode)
                        _buildEditModeLyrics()
                      else
                        _buildLyricsEditor(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
              _isEditMode ? 'Edit Notation' : 'Song Editor',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2, end: 0),
          ),

          // Edit Mode Toggle
          if (_lyricsController.text.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                gradient: _isEditMode
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                      )
                    : null,
                color: _isEditMode ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isEditMode
                      ? const Color(0xFFFF6B35)
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  _isEditMode ? Icons.visibility_rounded : Icons.edit_rounded,
                  color: Colors.white,
                ),
                onPressed: _toggleEditMode,
                tooltip: _isEditMode ? 'View Mode' : 'Edit Notation',
              ),
            ).animate().fadeIn(delay: 200.ms).scale(),
            const SizedBox(width: 12),
          ],

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
          ).animate().fadeIn(delay: 300.ms).scale(),
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
        if (_isEditMode) ...[
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.3),
                    const Color(0xFFF7931E).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
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
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Tap words to add notation',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .fadeIn(duration: 1500.ms),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildLyricsEditor() {
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
        controller: _lyricsController,
        maxLines: null,
        minLines: 12,
        style: GoogleFonts.poppins(
          fontSize: 16,
          height: 1.8,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your lyrics here...\n\nTap the eye icon to add notation',
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.3),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(24),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEditModeLyrics() {
    final lyrics = _lyricsController.text;
    if (lyrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(60),
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
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.2),
                      const Color(0xFFF7931E).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.music_note_outlined,
                  size: 60,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No lyrics yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add lyrics first to start adding notation',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotationDisplay(lyrics),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFFF6B35),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap words to add notation • Long press to remove',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNotationDisplay(String lyrics) {
    return Wrap(
      spacing: 10,
      runSpacing: 16,
      children: _buildLyricsSpans(lyrics),
    );
  }

  List<Widget> _buildLyricsSpans(String lyrics) {
    final List<Widget> widgets = [];
    int currentIndex = 0;

    final sortedSegments = List<NotationSegment>.from(_segments)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    for (final segment in sortedSegments) {
      if (currentIndex < segment.startIndex) {
        final text = lyrics.substring(currentIndex, segment.startIndex);
        widgets.addAll(_buildTextSpans(text, currentIndex));
        currentIndex = segment.startIndex;
      }

      final segmentText = lyrics.substring(segment.startIndex, segment.endIndex);
      widgets.add(_buildNotatedWord(segmentText, segment));
      currentIndex = segment.endIndex;
    }

    if (currentIndex < lyrics.length) {
      final text = lyrics.substring(currentIndex);
      widgets.addAll(_buildTextSpans(text, currentIndex));
    }

    return widgets;
  }

  List<Widget> _buildTextSpans(String text, int startIndex) {
    final words = text.split(RegExp(r'(\s+)'));
    final List<Widget> widgets = [];
    int offset = startIndex;

    for (final word in words) {
      if (word.trim().isEmpty) {
        offset += word.length;
        continue;
      }

      final wordStart = offset;
      final wordEnd = offset + word.length;
      widgets.add(_buildSelectableWord(word, wordStart, wordEnd));
      offset = wordEnd;
    }

    return widgets;
  }

  Widget _buildSelectableWord(String word, int start, int end) {
    return GestureDetector(
      onTap: () => _showSwaraKeyboard(start, end),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6B35).withOpacity(0.15),
              const Color(0xFFF7931E).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          word,
          style: GoogleFonts.poppins(
            fontSize: 16,
            height: 1.5,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNotatedWord(String word, NotationSegment segment) {
    return GestureDetector(
      onTap: () => _showSwaraKeyboard(segment.startIndex, segment.endIndex),
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
              color: const Color(0xFFFF6B35).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              segment.swarasDisplay,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              word,
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.5,
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
