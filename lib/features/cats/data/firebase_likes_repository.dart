import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/likes_repository.dart';
import '../models/cat_image.dart';
import 'likes_storage.dart';

class FirebaseLikesRepository implements LikesRepository {
  FirebaseLikesRepository(
    this._firestore, {
    LikesStorage? localStorage,
  }) : _localStorage = localStorage;

  final FirebaseFirestore _firestore;
  final LikesStorage? _localStorage;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('user_profiles');

  @override
  Future<List<CatImage>> loadLikes(String userId) async {
    try {
      final snapshot = await _profiles.doc(userId).get();
      final data = snapshot.data();
      final remoteCats = _parseLikedCats(data);
      if (_hasRemoteLikesData(data)) {
        return remoteCats;
      }
    } catch (_) {
      // Fall back to local cache below.
    }

    final localStorage = _localStorage;
    if (localStorage == null) {
      return [];
    }

    final localCats = await localStorage.loadLikes(userId);
    if (localCats.isNotEmpty) {
      try {
        await saveLikes(userId: userId, cats: localCats);
      } catch (_) {
        // Keep local likes available even if remote sync fails.
      }
    }
    return localCats;
  }

  @override
  Future<void> saveLikes({
    required String userId,
    required List<CatImage> cats,
  }) async {
    final uniqueCats = _dedupe(cats);
    await _profiles.doc(userId).set(
      {
        'likesCount': uniqueCats.length,
        'likedCats': uniqueCats.map((cat) => cat.toJson()).toList(growable: false),
        'likesUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final localStorage = _localStorage;
    if (localStorage != null) {
      await localStorage.saveLikes(userId, uniqueCats);
    }
  }

  List<CatImage> _parseLikedCats(Map<String, dynamic>? data) {
    if (data == null) {
      return [];
    }

    final rawCats = data['likedCats'];
    if (rawCats is! List) {
      return [];
    }

    return rawCats
        .whereType<Map>()
        .map((cat) => CatImage.fromJson(Map<String, dynamic>.from(cat)))
        .toList(growable: false);
  }

  bool _hasRemoteLikesData(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }
    return data.containsKey('likedCats') || data.containsKey('likesCount');
  }

  List<CatImage> _dedupe(List<CatImage> cats) {
    final unique = <String, CatImage>{};
    for (final cat in cats) {
      unique[cat.id] = cat;
    }
    return unique.values.toList(growable: false);
  }
}
