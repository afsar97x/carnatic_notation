import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/notation_segment.dart';
import '../models/note.dart';
import '../widgets/segment_editor.dart';

class EditorScreen extends StatefulWidget {
  final Song song;

  const EditorScreen({Key? key, required this.song}) : super(key: key);

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late Song _song;
  int? _selectedSegmentIndex;
  int? _selectedNoteIndex;
  final TextEditingController _syllableController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    // Add an empty segment if the song has none
    if (_song.segments.isEmpty) {
      _song.segments.add(NotationSegment.empty());
    }
  }

  void _addNote(String swara) {
    setState(() {
      if (_selectedSegmentIndex == null) {
        // Create a new segment
        _song.segments.add(NotationSegment(notes: [Note(swara: swara)], syllables: []));
        _selectedSegmentIndex = _song.segments.length - 1;
      } else {
        // Add to existing segment
        _song.segments[_selectedSegmentIndex!].notes.add(Note(swara: swara));
      }
      _selectedNoteIndex = _song.segments[_selectedSegmentIndex!].notes.length - 1;
    });
  }

  void _addSeparator(String separator) {
    _addNote(separator);
  }

  void _toggleModifier(String modifier) {
    if (_selectedSegmentIndex == null || _selectedNoteIndex == null) return;

    setState(() {
      final note = _song.segments[_selectedSegmentIndex!].notes[_selectedNoteIndex!];
      switch (modifier) {
        case 'upper_dot':
          _song.segments[_selectedSegmentIndex!].notes[_selectedNoteIndex!] =
              note.copyWith(hasUpperDot: !note.hasUpperDot);
          break;
        case 'lower_dot':
          _song.segments[_selectedSegmentIndex!].notes[_selectedNoteIndex!] =
              note.copyWith(hasLowerDot: !note.hasLowerDot);
          break;
        case 'underline':
          _song.segments[_selectedSegmentIndex!].notes[_selectedNoteIndex!] =
              note.copyWith(hasUnderline: !note.hasUnderline);
          break;
        case 'overline':
          _song.segments[_selectedSegmentIndex!].notes[_selectedNoteIndex!] =
              note.copyWith(hasOverline: !note.hasOverline);
          break;
      }
    });
  }

  void _addSyllable() {
    if (_selectedSegmentIndex == null || _syllableController.text.isEmpty) return;

    setState(() {
      _song.segments[_selectedSegmentIndex!].syllables.add(_syllableController.text);
      _syllableController.clear();
    });
  }

  void _newSegment() {
    setState(() {
      _song.segments.add(NotationSegment.empty());
      _selectedSegmentIndex = _song.segments.length - 1;
      _selectedNoteIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_song.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Implement save
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Save functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Song metadata
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                if (_song.raga != null) ...[
                  const Text('Raga: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_song.raga!),
                  const SizedBox(width: 20),
                ],
                if (_song.tala != null) ...[
                  const Text('Tala: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_song.tala!),
                ],
              ],
            ),
          ),

          // Notation editor area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._song.segments.asMap().entries.map((entry) {
                    int idx = entry.key;
                    NotationSegment segment = entry.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSegmentIndex = idx;
                          _selectedNoteIndex = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedSegmentIndex == idx
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SegmentEditor(
                          segment: segment,
                          selectedNoteIndex: _selectedSegmentIndex == idx
                              ? _selectedNoteIndex
                              : null,
                          onNoteTap: (noteIdx) {
                            setState(() {
                              _selectedSegmentIndex = idx;
                              _selectedNoteIndex = noteIdx;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Input toolbar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Note input buttons
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._buildNoteButtons(),
                      ..._buildSeparatorButtons(),
                    ],
                  ),
                ),

                // Modifier buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildModifierButton('Upper •', 'upper_dot'),
                      _buildModifierButton('Lower •', 'lower_dot'),
                      _buildModifierButton('Underline', 'underline'),
                      _buildModifierButton('Overline', 'overline'),
                    ],
                  ),
                ),

                // Syllable input
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _syllableController,
                          decoration: const InputDecoration(
                            hintText: 'Add syllable...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _addSyllable(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSyllable,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _newSegment,
                        icon: const Icon(Icons.add),
                        label: const Text('New Line'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNoteButtons() {
    const notes = ['S', 'R', 'G', 'M', 'P', 'D', 'N'];
    return notes.map((note) {
      return ElevatedButton(
        onPressed: () => _addNote(note),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(50, 40),
        ),
        child: Text(note),
      );
    }).toList();
  }

  List<Widget> _buildSeparatorButtons() {
    return [
      ElevatedButton(
        onPressed: () => _addSeparator('|'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(40, 40),
        ),
        child: const Text('|'),
      ),
      ElevatedButton(
        onPressed: () => _addSeparator('||'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(40, 40),
        ),
        child: const Text('||'),
      ),
    ];
  }

  Widget _buildModifierButton(String label, String modifier) {
    bool isActive = false;
    if (_selectedSegmentIndex != null && _selectedNoteIndex != null) {
      final note = _song.segments[_selectedSegmentIndex!].notes[_selectedNoteIndex!];
      switch (modifier) {
        case 'upper_dot':
          isActive = note.hasUpperDot;
          break;
        case 'lower_dot':
          isActive = note.hasLowerDot;
          break;
        case 'underline':
          isActive = note.hasUnderline;
          break;
        case 'overline':
          isActive = note.hasOverline;
          break;
      }
    }

    return ElevatedButton(
      onPressed: () => _toggleModifier(modifier),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : null,
        foregroundColor: isActive ? Colors.white : null,
      ),
      child: Text(label),
    );
  }

  @override
  void dispose() {
    _syllableController.dispose();
    super.dispose();
  }
}
