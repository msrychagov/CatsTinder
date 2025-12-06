class Breed {
  Breed({
    required this.id,
    required this.name,
    required this.description,
    required this.origin,
    required this.lifeSpan,
    required this.temperament,
    required this.energyLevel,
    required this.affectionLevel,
    required this.intelligence,
    required this.socialNeeds,
    this.referenceImageId,
  });

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Неизвестно',
      description: json['description'] as String? ?? '',
      origin: json['origin'] as String? ?? 'Неизвестно',
      lifeSpan: json['life_span'] as String? ?? '—',
      temperament: json['temperament'] as String? ?? '',
      energyLevel: json['energy_level'] as int? ?? 0,
      affectionLevel: json['affection_level'] as int? ?? 0,
      intelligence: json['intelligence'] as int? ?? 0,
      socialNeeds: json['social_needs'] as int? ?? 0,
      referenceImageId: json['reference_image_id'] as String?,
    );
  }

  final String id;
  final String name;
  final String description;
  final String origin;
  final String lifeSpan;
  final String temperament;
  final int energyLevel;
  final int affectionLevel;
  final int intelligence;
  final int socialNeeds;
  final String? referenceImageId;

  String get shortInfo => temperament;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'origin': origin,
        'life_span': lifeSpan,
        'temperament': temperament,
        'energy_level': energyLevel,
        'affection_level': affectionLevel,
        'intelligence': intelligence,
        'social_needs': socialNeeds,
        'reference_image_id': referenceImageId,
      };
}
