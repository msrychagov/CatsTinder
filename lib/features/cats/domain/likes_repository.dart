import '../models/cat_image.dart';

abstract class LikesRepository {
  Future<List<CatImage>> loadLikes(String userId);

  Future<void> saveLikes({
    required String userId,
    required List<CatImage> cats,
  });
}
