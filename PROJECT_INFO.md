# Carnatic Notation App - Project Documentation

## Project Overview

A Flutter-based desktop (macOS) and mobile (iOS) application for creating and managing Carnatic music notations. The app solves the problem of aligning musical notes (swaras) with lyrics (sahitya) which is tedious and error-prone in conventional text editors like Microsoft Word or Notes.

## Problem Statement

Traditional text editors fail at:
1. **Alignment issues** - keeping notations above the right syllables
2. **Flexible mapping** - sometimes 3 letters need 1 note, or 2 letters need 4 grouped notes
3. **Special symbols** - dots above/below notes, underlines/overlines spanning groups
4. **Editing breaks formatting** - any change disrupts the alignment

## Target Users

Carnatic music singers who need to:
- Notate songs with proper swara-syllable alignment
- Add modifiers (octave markers, grouping indicators)
- Share and print notations in clean format

## Core Features (MVP)

### 1. Smart Note Input
- **Basic notes**: S, R, G, M, P, D, N
- **Separators**: | (single bar), || (double bar)
- **Modifiers**:
  - Upper dot (•) - Tara sthayi (upper octave)
  - Lower dot (•) - Mandra sthayi (lower octave)
  - Underline - Grouping indicator
  - Overline - Grouping indicator

### 2. Perfect Alignment
- Note row aligned with syllable row
- Flexible mapping (1:1, 1:many, many:1)
- Visual segments maintain alignment during edits

### 3. Essential Editing
- Undo/redo capability
- Select notes and toggle modifiers
- Add/remove notes and syllables
- Create new line segments

### 4. Organization
- Local library of songs
- Song metadata: title, raga, tala, composer
- Create, edit, delete songs

### 5. Beautiful UX
- Dark/light theme (follows system)
- Clean, distraction-free interface
- Material Design 3
- Touch-optimized for mobile, keyboard-optimized for desktop

### 6. Data Persistence
- **iCloud sync** (FREE, built into Apple devices)
- Automatic sync between iPhone/Mac
- JSON-based data format

## Features NOT Included (Out of Scope)

- ❌ Voice transcription
- ❌ OCR from handwritten notes (maybe future)
- ❌ Music-specific tools (raga palette, tala ruler)
- ❌ Practice features (metronome, playback)
- ❌ AI assistance
- ❌ Android support (iOS/macOS only)

## Reference Examples

Based on notation styles from:
1. **shivkumar.org** - Clean table format with notes/syllables aligned
2. **beautifulnote.com** - Grouped notes with underlines/overlines

### Example Notation Format:
```
M    P    |  D    S    S    R    ||  R    S    |
Sree  -   |  Ga   na   na   tha  ||  sin  dhu |
```

Key observations:
- Notes can be single or grouped (pm, mpmd pm, srm)
- Dots above/below for octave markers
- Underlines/overlines span grouped notes
- Bars separate phrases
- Flexible syllable-to-note mapping

## Technical Architecture

### Tech Stack
- **Framework**: Flutter 3.35.5
- **Platforms**: iOS, macOS
- **Language**: Dart
- **Sync**: iCloud (native Apple)
- **Design**: Material Design 3

### Data Models

#### Note
```dart
class Note {
  String swara;          // S, R, G, M, P, D, N, |, ||
  bool hasUpperDot;      // Tara sthayi
  bool hasLowerDot;      // Mandra sthayi
  bool hasUnderline;     // Grouping
  bool hasOverline;      // Grouping
}
```

#### NotationSegment
```dart
class NotationSegment {
  List<Note> notes;           // Multiple notes
  List<String> syllables;     // Multiple syllables
}
```

#### Song
```dart
class Song {
  String id;
  String title;
  String? raga;
  String? tala;
  String? composer;
  List<NotationSegment> segments;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── note.dart               # Note model with modifiers
│   ├── notation_segment.dart   # Segment (notes + syllables)
│   └── song.dart               # Song with metadata
├── screens/
│   ├── home_screen.dart        # Song library/list
│   └── editor_screen.dart      # Notation editor
└── widgets/
    ├── note_display.dart       # Single note widget
    └── segment_editor.dart     # Segment widget
```

## Current Implementation Status

### ✅ Completed
- [x] Flutter project setup
- [x] Data models (Note, Segment, Song)
- [x] Home screen with song library
- [x] Editor screen with note/syllable input
- [x] Modifier support (dots, underlines, overlines)
- [x] Dark/light theme
- [x] Basic UI/UX
- [x] App running on macOS

### 🔜 Next Steps (Priority)
1. **Better grouping** - Underline/overline should span multiple notes visually
2. **Export to PDF** - Print-ready format
3. **Export to PNG** - Share on WhatsApp/social media
4. **Keyboard shortcuts** - Faster input on Mac (S, R, G, M keys)
5. **Song metadata editor** - Edit raga/tala/composer fields
6. **iCloud persistence** - Save/load songs from iCloud
7. **Search functionality** - Find songs by title/raga
8. **Copy/paste segments** - Reuse notation patterns
9. **iOS support** - Test and optimize for iPhone/iPad

### 🎯 Future Enhancements (Maybe)
- OCR for handwritten notes
- Export to plain text format
- Custom fonts for Tamil/Telugu/Sanskrit lyrics
- Gesture-based editing on mobile
- Undo/redo history

## How to Run

### Prerequisites
- macOS with Xcode installed
- Flutter SDK installed
- CocoaPods installed

### Commands
```bash
# Navigate to project
cd carnatic_notation

# Run on macOS
flutter run -d macos

# Run on iOS (with device connected)
flutter run -d ios

# Build for release (macOS)
flutter build macos --release

# Build for release (iOS)
flutter build ios --release
```

### Development
- Hot reload: Press `r` in terminal
- Hot restart: Press `R` in terminal
- Quit: Press `q` in terminal

## Design Decisions

### Why Flutter?
- Single codebase for iOS + macOS
- Beautiful, native-feeling UI
- Fast development with hot reload
- Excellent performance

### Why iCloud?
- Free (no backend costs)
- Built into Apple ecosystem
- Users expect it
- Automatic sync, no login needed
- Secure and private

### Why Material Design?
- Modern, clean aesthetic
- Consistent across platforms
- Accessibility built-in
- Dark/light themes

### Why Segments?
- Flexible note-to-syllable mapping
- Easy to edit without breaking alignment
- Natural grouping for notation
- Matches how singers think about phrases

## Known Issues

1. **Overline/underline rendering** - Currently only affects single note, should span groups
2. **No persistence yet** - Songs lost when app closes
3. **No export yet** - Can't share or print notations
4. **Limited keyboard support** - Must click buttons to input

## Contact & Feedback

Project built collaboratively with Claude Code.
Session started: 2025-10-03

---

## Session Notes

### Requirements Discussion
- User is familiar with Carnatic music notation
- Showed reference images from shivkumar.org and beautifulnote.com
- Wants clean, efficient notation tool (not over-ambitious)
- Focus on being "the best at note-taking"

### Installation Steps Completed
1. ✅ Homebrew already installed
2. ✅ Xcode Command Line Tools installed
3. ✅ Flutter installed via brew (3.35.5)
4. ✅ Xcode license accepted
5. ✅ CocoaPods installed via brew
6. ✅ macOS desktop support enabled

### Key Design Choices
- Skip Android (focus on iOS/macOS)
- Skip voice/OCR/AI features (focus on core notation)
- Use iCloud for free sync
- Material Design for modern feel
- Segment-based data model for flexibility
