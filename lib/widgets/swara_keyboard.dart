import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/swara.dart';

class SwaraKeyboard extends StatefulWidget {
  final Function(List<Swara>) onSwarasChanged;
  final List<Swara> initialSwaras;

  const SwaraKeyboard({
    super.key,
    required this.onSwarasChanged,
    this.initialSwaras = const [],
  });

  @override
  State<SwaraKeyboard> createState() => _SwaraKeyboardState();
}

class _SwaraKeyboardState extends State<SwaraKeyboard> {
  late List<Swara> _currentSwaras;

  @override
  void initState() {
    super.initState();
    _currentSwaras = List.from(widget.initialSwaras);
  }

  void _addSwara(SwaraNote note) {
    setState(() {
      _currentSwaras.add(Swara(note: note));
      widget.onSwarasChanged(_currentSwaras);
    });
  }

  void _cycleLastSwaraOctave() {
    if (_currentSwaras.isEmpty) return;
    setState(() {
      final lastIndex = _currentSwaras.length - 1;
      _currentSwaras[lastIndex] = _currentSwaras[lastIndex].cycleOctave();
      widget.onSwarasChanged(_currentSwaras);
    });
  }

  void _removeLastSwara() {
    if (_currentSwaras.isEmpty) return;
    setState(() {
      _currentSwaras.removeLast();
      widget.onSwarasChanged(_currentSwaras);
    });
  }

  void _clear() {
    setState(() {
      _currentSwaras.clear();
      widget.onSwarasChanged(_currentSwaras);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Display current swaras
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notation',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentSwaras.isEmpty
                            ? 'Tap notes below...'
                            : _currentSwaras.map((s) => s.display).join(' '),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(),

                const SizedBox(height: 20),

                // Instruction text
                Text(
                  'Tap note to add • Tap again to change octave',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),

                const SizedBox(height: 16),

                // Swara buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: SwaraNote.values.map((note) {
                    return _buildSwaraButton(note);
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.backspace_outlined,
                        label: 'Delete',
                        onPressed: _currentSwaras.isEmpty ? null : _removeLastSwara,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.arrow_upward,
                        label: 'Cycle',
                        onPressed: _currentSwaras.isEmpty ? null : _cycleLastSwaraOctave,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.clear_all,
                        label: 'Clear',
                        onPressed: _currentSwaras.isEmpty ? null : _clear,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Done button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwaraButton(SwaraNote note) {
    return GestureDetector(
      onTap: () => _addSwara(note),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            note.symbol,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, delay: (SwaraNote.values.indexOf(note) * 100).ms);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: onPressed == null
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
              : color,
          side: BorderSide(
            color: onPressed == null
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.2)
                : color.withOpacity(0.5),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
