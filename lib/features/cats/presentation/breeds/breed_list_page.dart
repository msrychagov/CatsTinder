import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/cat_api_service.dart';
import '../../models/breed.dart';
import '../detail/cat_detail_page.dart';
import '../widgets/background_gradient.dart';

class BreedListPage extends StatefulWidget {
  const BreedListPage({super.key, required this.service});

  final CatApiService service;

  @override
  State<BreedListPage> createState() => _BreedListPageState();
}

class _BreedListPageState extends State<BreedListPage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Breed>> _breedsFuture;
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _breedsFuture = widget.service.fetchBreeds();
  }

  Future<void> _reload() async {
    setState(() {
      _breedsFuture = widget.service.fetchBreeds();
      _errorShown = false;
    });
    await _breedsFuture;
  }

  void _maybeShowError(Object? error) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    final message = error?.toString() ?? 'Неизвестная ошибка';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка сети'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reload();
              },
              child: const Text('Обновить'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        const BackgroundGradient(),
        FutureBuilder<List<Breed>>(
          future: _breedsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (snapshot.hasError) {
              _maybeShowError(snapshot.error);
              return _ErrorState(
                message: 'Не удалось получить список пород',
                onRetry: _reload,
              );
            }
            final breeds = snapshot.data ?? [];
            return RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.white,
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemBuilder: (context, index) {
                  final breed = breeds[index];
                  return _BreedCard(
                    breed: breed,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BreedDetailPage(breed: breed),
                        ),
                      );
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: breeds.length,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _BreedCard extends StatelessWidget {
  const _BreedCard({required this.breed, required this.onTap});

  final Breed breed;
  final VoidCallback onTap;

  String? get _referenceImageUrl {
    final id = breed.referenceImageId;
    if (id == null || id.isEmpty) return null;
    return 'https://cdn2.thecatapi.com/images/$id.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: _referenceImageUrl == null
                    ? Container(
                        color: Colors.white.withValues(alpha: 0.04),
                        child: const Icon(Icons.pets, color: Colors.white54),
                      )
                    : CachedNetworkImage(
                        imageUrl: _referenceImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => Container(
                          color: Colors.white.withValues(alpha: 0.04),
                          child: const Center(
                              child: CircularProgressIndicator.adaptive()),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.pets, color: Colors.white54),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      breed.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${breed.origin} • ${breed.lifeSpan} лет',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      breed.shortInfo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white54, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }
}
