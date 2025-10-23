import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get songs collection reference for a user
  CollectionReference _songsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('songs');
  }

  /// Stream of all songs for a user
  Stream<List<Song>> getSongsStream(String userId) {
    return _songsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Song.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  /// Get a single song
  Future<Song?> getSong(String userId, String songId) async {
    final doc = await _songsCollection(userId).doc(songId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return Song.fromJson({...data, 'id': doc.id});
  }

  /// Create a new song
  Future<String> createSong(Song song) async {
    final docRef = await _songsCollection(song.userId).add(song.toJson());
    return docRef.id;
  }

  /// Update an existing song
  Future<void> updateSong(Song song) async {
    await _songsCollection(song.userId).doc(song.id).update(song.toJson());
  }

  /// Delete a song
  Future<void> deleteSong(String userId, String songId) async {
    await _songsCollection(userId).doc(songId).delete();
  }

  /// Search songs by title
  Future<List<Song>> searchSongs(String userId, String query) async {
    final snapshot = await _songsCollection(userId).get();
    final songs = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Song.fromJson({...data, 'id': doc.id});
    }).toList();

    return songs
        .where((song) =>
            song.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
