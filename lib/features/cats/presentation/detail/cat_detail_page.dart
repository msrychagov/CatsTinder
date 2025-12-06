import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/cat_image.dart';
import '../../models/breed.dart';
import '../widgets/section_card.dart';

class CatDetailPage extends StatelessWidget {
  const CatDetailPage({super.key, required this.cat});

  final CatImage cat;

  @override
  Widget build(BuildContext context) {
    final breed = cat.breed;
    const BorderRadius heroBorder = BorderRadius.all(Radius.circular(32));
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(title: Text(breed.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: cat.id,
            child: ClipRRect(
              borderRadius: heroBorder,
              child: AspectRatio(
                aspectRatio: cat.aspectRatio ?? 4 / 5,
                child: CachedNetworkImage(
                  imageUrl: cat.url,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: Colors.white.withValues(alpha: 0.06),
                    child: const Center(
                        child: CircularProgressIndicator.adaptive()),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            breed.name,
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${breed.origin} • ${breed.temperament}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Описание',
            child: Text(
              breed.description,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          CharacteristicsGrid(breed: breed),
        ],
      ),
    );
  }
}

class BreedDetailPage extends StatelessWidget {
  const BreedDetailPage({super.key, required this.breed});

  final Breed breed;

  String? get _referenceImageUrl {
    if (breed.referenceImageId == null || breed.referenceImageId!.isEmpty) {
      return null;
    }
    return 'https://cdn2.thecatapi.com/images/${breed.referenceImageId}.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(title: Text(breed.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _referenceImageUrl == null
                ? Container(
                    height: 260,
                    color: Colors.white.withValues(alpha: 0.06),
                    child:
                        const Icon(Icons.pets, color: Colors.white54, size: 64),
                  )
                : CachedNetworkImage(
                    imageUrl: _referenceImageUrl!,
                    height: 260,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => Container(
                      height: 260,
                      color: Colors.white.withValues(alpha: 0.06),
                      child: const Center(
                          child: CircularProgressIndicator.adaptive()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 260,
                      color: Colors.white.withValues(alpha: 0.06),
                      child: const Icon(Icons.pets,
                          color: Colors.white54, size: 64),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            breed.name,
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${breed.origin} • ${breed.lifeSpan} лет жизни',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Описание',
            child: Text(
              breed.description,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          CharacteristicsGrid(breed: breed),
        ],
      ),
    );
  }
}

class CharacteristicsGrid extends StatelessWidget {
  const CharacteristicsGrid({super.key, required this.breed});

  final Breed breed;

  @override
  Widget build(BuildContext context) {
    final characteristics = [
      _Characteristic('Энергия', breed.energyLevel),
      _Characteristic('Интеллект', breed.intelligence),
      _Characteristic('Ласковость', breed.affectionLevel),
      _Characteristic('Социальность', breed.socialNeeds),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: characteristics.length,
      itemBuilder: (context, index) {
        final item = characteristics[index];
        return SectionCard(
          title: item.title,
          child: Meter(level: item.level),
        );
      },
    );
  }
}

class _Characteristic {
  const _Characteristic(this.title, this.level);

  final String title;
  final int level;
}
