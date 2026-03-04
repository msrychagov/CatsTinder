class UserProfile {
  const UserProfile({
    required this.description,
    required this.energyLevel,
    required this.intelligence,
    required this.affectionLevel,
    required this.socialNeeds,
    required this.photoPath,
  });

  final String description;
  final int energyLevel;
  final int intelligence;
  final int affectionLevel;
  final int socialNeeds;
  final String photoPath;

  UserProfile copyWith({
    String? description,
    int? energyLevel,
    int? intelligence,
    int? affectionLevel,
    int? socialNeeds,
    String? photoPath,
  }) {
    return UserProfile(
      description: description ?? this.description,
      energyLevel: energyLevel ?? this.energyLevel,
      intelligence: intelligence ?? this.intelligence,
      affectionLevel: affectionLevel ?? this.affectionLevel,
      socialNeeds: socialNeeds ?? this.socialNeeds,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'energyLevel': energyLevel,
        'intelligence': intelligence,
        'affectionLevel': affectionLevel,
        'socialNeeds': socialNeeds,
        'photoPath': photoPath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      description: json['description'] as String? ?? '',
      energyLevel: (json['energyLevel'] as num?)?.toInt() ?? 0,
      intelligence: (json['intelligence'] as num?)?.toInt() ?? 0,
      affectionLevel: (json['affectionLevel'] as num?)?.toInt() ?? 0,
      socialNeeds: (json['socialNeeds'] as num?)?.toInt() ?? 0,
      photoPath: json['photoPath'] as String? ?? '',
    );
  }
}
