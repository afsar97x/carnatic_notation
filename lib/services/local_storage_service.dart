import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class LocalStorageService {
  static const String _songsKey = 'songs';

  /// Get all songs
  Future<List<Song>> getSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final songsJson = prefs.getString(_songsKey);

    if (songsJson == null) {
      return [];
    }

    try {
      final List<dynamic> songsList = json.decode(songsJson);
      return songsList.map((json) => Song.fromJson(json)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      print('Error loading songs: $e');
      return [];
    }
  }

  /// Save all songs
  Future<void> _saveSongs(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final songsJson = json.encode(songs.map((s) => s.toJson()).toList());
    await prefs.setString(_songsKey, songsJson);
  }

  /// Create a new song
  Future<String> createSong(Song song) async {
    final songs = await getSongs();
    songs.add(song);
    await _saveSongs(songs);
    return song.id;
  }

  /// Update an existing song
  Future<void> updateSong(Song song) async {
    final songs = await getSongs();
    final index = songs.indexWhere((s) => s.id == song.id);

    if (index != -1) {
      songs[index] = song;
      await _saveSongs(songs);
    }
  }

  /// Delete a song
  Future<void> deleteSong(String songId) async {
    final songs = await getSongs();
    songs.removeWhere((s) => s.id == songId);
    await _saveSongs(songs);
  }

  /// Search songs by title
  Future<List<Song>> searchSongs(String query) async {
    final songs = await getSongs();
    return songs
        .where((song) => song.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
