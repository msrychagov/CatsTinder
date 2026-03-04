import '../domain/cats_repository.dart';
import '../models/breed.dart';
import '../models/cat_image.dart';
import 'cat_api_service.dart';

class TheCatApiCatsRepository implements CatsRepository {
  const TheCatApiCatsRepository(this._service);

  final CatApiService _service;

  @override
  Future<CatImage> fetchRandomCat() {
    return _service.fetchRandomCat();
  }

  @override
  Future<List<Breed>> fetchBreeds() {
    return _service.fetchBreeds();
  }
}
