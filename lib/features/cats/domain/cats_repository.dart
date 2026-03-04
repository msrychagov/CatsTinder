import '../models/breed.dart';
import '../models/cat_image.dart';

abstract class CatsRepository {
  Future<CatImage> fetchRandomCat();

  Future<List<Breed>> fetchBreeds();
}
