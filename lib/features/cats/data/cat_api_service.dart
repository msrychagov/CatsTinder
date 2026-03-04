import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../domain/cats_failure.dart';
import '../models/breed.dart';
import '../models/cat_image.dart';

class CatApiService {
  CatApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://api.thecatapi.com/v1';
  final http.Client _client;
  Future<List<Breed>>? _breedsFuture;

  Future<CatImage> fetchRandomCat() async {
    final quick = await _attemptFetchWithFlag();
    if (quick != null) return quick;

    final breeds = await fetchBreeds();
    breeds.shuffle(Random());
    for (final breed in breeds) {
      final cat = await _fetchByBreed(breed);
      if (cat != null) return cat;
    }
    throw CatsFailure(
        'Сервис не прислал котика с породой. Попробуйте ещё раз.');
  }

  Future<List<Breed>> fetchBreeds() async {
    final future = _breedsFuture ??= _loadBreeds();
    return future;
  }

  Future<List<Breed>> _loadBreeds() async {
    final uri = Uri.parse('$_baseUrl/breeds');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw CatsFailure('Код ответа: ${response.statusCode}');
    }
    final data = json.decode(response.body) as List<dynamic>;
    return data.map((e) => Breed.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CatImage?> _attemptFetchWithFlag() async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final uri = Uri.parse('$_baseUrl/images/search?has_breeds=1');
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        throw CatsFailure('Код ответа: ${response.statusCode}');
      }
      final data = json.decode(response.body) as List<dynamic>;
      if (data.isEmpty) continue;
      final item = data.first as Map<String, dynamic>;
      final breeds = item['breeds'] as List<dynamic>? ?? [];
      if (breeds.isEmpty) continue;
      return CatImage.fromJson(item);
    }
    return null;
  }

  Future<CatImage?> _fetchByBreed(Breed breed) async {
    final uri =
        Uri.parse('$_baseUrl/images/search?breed_ids=${breed.id}&limit=1');
    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as List<dynamic>;
    if (data.isEmpty) return null;
    final item = data.first as Map<String, dynamic>;
    final url = item['url'] as String? ?? '';
    if (url.isEmpty) return null;
    final width = (item['width'] as num?)?.toDouble();
    final height = (item['height'] as num?)?.toDouble();
    return CatImage(
      id: item['id'] as String? ?? url,
      url: url,
      breed: breed,
      aspectRatio:
          width != null && height != null && height > 0 ? width / height : null,
    );
  }
}
