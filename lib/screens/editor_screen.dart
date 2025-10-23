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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a song title', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
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
        // New song or local song
        await localStorage.createSong(updatedSong);
      } else {
        await localStorage.updateSong(updatedSong);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Song saved!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving song: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  void _showSwaraKeyboard(int start, int end) {
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
              // Remove any existing segments that overlap with this selection
              _segments.removeWhere((seg) => seg.overlapsWith(start, end));

              if (swaras.isNotEmpty) {
                // Add new segment
                _segments.add(NotationSegment(
                  id: const Uuid().v4(),
                  startIndex: start,
                  endIndex: end,
                  swaras: swaras,
                ));
              }

              // Sort segments by start index
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
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Notation' : 'Song Editor',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_lyricsController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                _isEditMode ? Icons.visibility : Icons.edit,
                color: _isEditMode ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: _toggleEditMode,
              tooltip: _isEditMode ? 'View Mode' : 'Edit Notation',
            ),
          IconButton(
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSong,
            tooltip: 'Save Song',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _titleController,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Song Title',
                    hintStyle: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    prefixIcon: Icon(
                      Icons.title,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Lyrics Label
              Row(
                children: [
                  Text(
                    'Lyrics',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  if (_isEditMode) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Select text to add notation',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .fadeIn(duration: 1000.ms),
                  ],
                ],
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              // Lyrics Display/Editor
              if (_isEditMode)
                _buildEditModeLyrics()
              else
                _buildLyricsEditor(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _lyricsController,
        maxLines: null,
        minLines: 10,
        style: GoogleFonts.poppins(
          fontSize: 16,
          height: 1.8,
        ),
        decoration: InputDecoration(
          hintText: 'Enter lyrics here...',
          hintStyle: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEditModeLyrics() {
    final lyrics = _lyricsController.text;
    if (lyrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Add lyrics first to start adding notation',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display notation and lyrics
          _buildNotationDisplay(lyrics),
          const SizedBox(height: 24),
          // Selection helper
          Text(
            'Tap any word or select text to add notation',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNotationDisplay(String lyrics) {
    return Wrap(
      spacing: 8,
      runSpacing: 16,
      children: _buildLyricsSpans(lyrics),
    );
  }

  List<Widget> _buildLyricsSpans(String lyrics) {
    final List<Widget> widgets = [];
    int currentIndex = 0;

    // Sort segments by start index
    final sortedSegments = List<NotationSegment>.from(_segments)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    for (final segment in sortedSegments) {
      // Add text before this segment (if any)
      if (currentIndex < segment.startIndex) {
        final text = lyrics.substring(currentIndex, segment.startIndex);
        widgets.addAll(_buildTextSpans(text, currentIndex));
        currentIndex = segment.startIndex;
      }

      // Add segment with notation
      final segmentText = lyrics.substring(segment.startIndex, segment.endIndex);
      widgets.add(_buildNotatedWord(segmentText, segment));
      currentIndex = segment.endIndex;
    }

    // Add remaining text
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Text(
          word,
          style: GoogleFonts.poppins(
            fontSize: 16,
            height: 1.8,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildNotatedWord(String word, NotationSegment segment) {
    return GestureDetector(
      onTap: () => _showSwaraKeyboard(segment.startIndex, segment.endIndex),
      onLongPress: () {
        // Long press to delete notation
        setState(() {
          _segments.removeWhere((s) => s.id == segment.id);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notation
            Text(
              segment.swarasDisplay,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            // Lyrics
            Text(
              word,
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.8,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
