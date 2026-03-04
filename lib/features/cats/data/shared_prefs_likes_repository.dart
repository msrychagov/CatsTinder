import '../domain/likes_repository.dart';
import '../models/cat_image.dart';
import 'likes_storage.dart';

class SharedPrefsLikesRepository implements LikesRepository {
  const SharedPrefsLikesRepository(this._storage);

  final LikesStorage _storage;

  @override
  Future<List<CatImage>> loadLikes(String userId) {
    return _storage.loadLikes(userId);
  }

  @override
  Future<void> saveLikes({
    required String userId,
    required List<CatImage> cats,
  }) {
    return _storage.saveLikes(userId, cats);
  }
}
