import 'package:flutter/material.dart';
import '../models/song.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Song> _songs = [];
  final TextEditingController _titleController = TextEditingController();

  void _createNewSong() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Song'),
        content: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Song title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                final song = Song.create(title: _titleController.text);
                setState(() {
                  _songs.add(song);
                });
                _titleController.clear();
                Navigator.pop(context);
                _openEditor(song);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openEditor(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(song: song),
      ),
    ).then((_) => setState(() {})); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnatic Notation'),
        elevation: 0,
      ),
      body: _songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No songs yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first notation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.music_note),
                    ),
                    title: Text(
                      song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: song.raga != null || song.tala != null
                        ? Text(
                            [
                              if (song.raga != null) 'Raga: ${song.raga}',
                              if (song.tala != null) 'Tala: ${song.tala}',
                            ].join(' • '),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _songs.removeAt(index);
                        });
                      },
                    ),
                    onTap: () => _openEditor(song),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewSong,
        icon: const Icon(Icons.add),
        label: const Text('New Song'),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
