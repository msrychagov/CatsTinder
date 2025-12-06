import 'breed.dart';

class CatImage {
  CatImage({
    required this.id,
    required this.url,
    required this.breed,
    this.aspectRatio,
  });

  factory CatImage.fromJson(Map<String, dynamic> json) {
    final breeds = json['breeds'] as List<dynamic>? ?? [];
    if (breeds.isEmpty) {
      throw Exception('Сервер вернул котика без данных породы');
    }
    final width = (json['width'] as num?)?.toDouble();
    final height = (json['height'] as num?)?.toDouble();
    final aspect = (json['aspectRatio'] as num?)?.toDouble();
    return CatImage(
      id: json['id'] as String? ?? json['url'] as String? ?? 'cat',
      url: json['url'] as String? ?? '',
      breed: Breed.fromJson(breeds.first as Map<String, dynamic>),
      aspectRatio: aspect ??
          (width != null && height != null && height > 0 ? width / height : null),
    );
  }

  final String id;
  final String url;
  final Breed breed;
  final double? aspectRatio;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'breeds': [breed.toJson()],
        if (aspectRatio != null) 'aspectRatio': aspectRatio,
      };
}
