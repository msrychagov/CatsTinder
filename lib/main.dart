import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF59E0B);
    return MaterialApp(
      title: 'Кототиндер',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.manropeTextTheme(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: CatHome(service: CatApiService()),
    );
  }
}

class CatHome extends StatefulWidget {
  const CatHome({super.key, required this.service});

  final CatApiService service;

  @override
  State<CatHome> createState() => _CatHomeState();
}

class _CatHomeState extends State<CatHome> {
  final List<CatImage> _likedCats = [];

  void _addLike(CatImage cat) {
    final exists = _likedCats.any((c) => c.id == cat.id);
    if (exists) return;
    setState(() => _likedCats.add(cat));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Кототиндер',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Лента'),
              Tab(text: 'Породы'),
              Tab(text: 'Лайки'),
            ],
            indicatorColor: Color(0xFFF59E0B),
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: TabBarView(
          children: [
            CatSwipePage(
              service: widget.service,
              likedCats: _likedCats,
              onLike: _addLike,
            ),
            BreedListPage(service: widget.service),
            LikedCatsPage(likedCats: _likedCats),
          ],
        ),
      ),
    );
  }
}

class CatSwipePage extends StatefulWidget {
  const CatSwipePage({
    super.key,
    required this.service,
    required this.likedCats,
    required this.onLike,
  });

  final CatApiService service;
  final List<CatImage> likedCats;
  final ValueChanged<CatImage> onLike;

  @override
  State<CatSwipePage> createState() => _CatSwipePageState();
}

class _CatSwipePageState extends State<CatSwipePage>
    with AutomaticKeepAliveClientMixin {
  CatImage? _currentCat;
  bool _loading = false;
  bool _errorVisible = false;

  @override
  void initState() {
    super.initState();
    _loadNextCat();
  }

  Future<void> _loadNextCat() async {
    setState(() => _loading = true);
    try {
      final cat = await widget.service.fetchRandomCat();
      if (!mounted) return;
      setState(() {
        _currentCat = cat;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showErrorDialog(
        e is CatApiException ? e.message : 'Не удалось загрузить котика. $e',
      );
    }
  }

  void _dislike() {
    if (_loading) return;
    _loadNextCat();
  }

  void _like() {
    if (_loading) return;
    final cat = _currentCat;
    if (cat != null) widget.onLike(cat);
    _loadNextCat();
  }

  void _openDetail() {
    final cat = _currentCat;
    if (cat == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CatDetailPage(cat: cat)),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    if (_errorVisible || !mounted) return;
    _errorVisible = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              _errorVisible = false;
              Navigator.of(context).pop();
            },
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              _errorVisible = false;
              Navigator.of(context).pop();
              _loadNextCat();
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        const _BackgroundGradient(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Свайпай котиков',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    _LikesPill(likes: widget.likedCats.length),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _loading
                          ? const _LoadingCard()
                          : _currentCat == null
                              ? const _PlaceholderCard()
                              : _CatCard(
                                  key: ValueKey(_currentCat!.id),
                                  cat: _currentCat!,
                                  onTap: _openDetail,
                                  onLike: _like,
                                  onDislike: _dislike,
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Дизлайк',
                        icon: Icons.close_rounded,
                        color: Colors.white12,
                        textColor: Colors.white,
                        onPressed: _dislike,
                        elevation: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'Лайк',
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFFFB703),
                        textColor: Colors.black,
                        onPressed: _like,
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _CatCard extends StatefulWidget {
  const _CatCard({
    super.key,
    required this.cat,
    required this.onLike,
    required this.onDislike,
    required this.onTap,
  });

  final CatImage cat;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onTap;

  @override
  State<_CatCard> createState() => _CatCardState();
}

class _CatCardState extends State<_CatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250))
    ..addListener(_onAnimate);
  Animation<Offset>? _offsetAnimation;
  Offset _offset = Offset.zero;
  double _angle = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAnimate() {
    if (_offsetAnimation != null) {
      setState(() {
        _offset = _offsetAnimation!.value;
        _angle = _offset.dx / MediaQuery.of(context).size.width * 0.15;
      });
    }
  }

  void _animateTo(Offset target, {VoidCallback? onCompleted}) {
    _offsetAnimation = Tween<Offset>(begin: _offset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller
      ..reset()
      ..forward().whenComplete(() {
        if (onCompleted != null) onCompleted();
      });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dx = _offset.dx + details.delta.dx;
    final dy = _offset.dy + details.delta.dy;
    final width = MediaQuery.of(context).size.width;
    setState(() {
      _offset = Offset(dx, dy);
      _angle = dx / width * 0.15;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final width = MediaQuery.of(context).size.width;
    const threshold = 0.25;
    final normalized = _offset.dx / width;
    if (normalized.abs() > threshold) {
      final direction = normalized.sign;
      final target = Offset(direction * width * 1.4, _offset.dy);
      _animateTo(target, onCompleted: () {
        direction > 0 ? widget.onLike() : widget.onDislike();
        _resetPosition();
      });
    } else {
      _animateTo(Offset.zero, onCompleted: _resetPosition);
    }
  }

  void _resetPosition() {
    if (!mounted) return;
    setState(() {
      _offset = Offset.zero;
      _angle = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final breed = widget.cat.breed;
    final imageHeight = min(MediaQuery.of(context).size.height * 0.55, 520.0);
    final overlayOpacity = (_offset.dx.abs() / 140).clamp(0.0, 1.0);
    final isLike = _offset.dx > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.translate(
          offset: _offset,
          child: Transform.rotate(
            angle: _angle,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Hero(
                    tag: widget.cat.id,
                    child: SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: widget.cat.url,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (context, _) => Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        ),
                        errorWidget: (context, _, __) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.72),
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            breed.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${breed.origin} • ${breed.temperament}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: overlayOpacity,
                        child: Container(
                          color: (isLike
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626))
                              .withValues(alpha: 0.22),
                          child: Align(
                            alignment:
                                isLike ? Alignment.topLeft : Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                isLike
                                    ? Icons.favorite_rounded
                                    : Icons.close_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LikesPill extends StatelessWidget {
  const _LikesPill({required this.likes});

  final int likes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded,
              color: Color(0xFFF472B6), size: 18),
          const SizedBox(width: 6),
          Text(
            '$likes',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onPressed,
    this.elevation = 0,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: elevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonCard();
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonCard(
      child: Text(
        'Тут будет котик',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: child ?? const CircularProgressIndicator.adaptive(),
      ),
    );
  }
}

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
        const _BackgroundGradient(),
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

class LikedCatsPage extends StatefulWidget {
  const LikedCatsPage({super.key, required this.likedCats});

  final List<CatImage> likedCats;

  @override
  State<LikedCatsPage> createState() => _LikedCatsPageState();
}

class _LikedCatsPageState extends State<LikedCatsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final liked = widget.likedCats.reversed.toList();
    if (liked.isEmpty) {
      return const Stack(
        children: [
          _BackgroundGradient(),
          Center(
            child: Text(
              'Пока нет лайкнутых котиков',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        const _BackgroundGradient(),
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemBuilder: (context, index) {
            final cat = liked[index];
            return _LikedCard(cat: cat);
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: liked.length,
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _LikedCard extends StatelessWidget {
  const _LikedCard({required this.cat});

  final CatImage cat;

  @override
  Widget build(BuildContext context) {
    final breed = cat.breed;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CatDetailPage(cat: cat)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breed.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${breed.origin} • ${breed.temperament}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class CatDetailPage extends StatelessWidget {
  const CatDetailPage({super.key, required this.cat});

  final CatImage cat;

  @override
  Widget build(BuildContext context) {
    final breed = cat.breed;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(title: Text(breed.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: cat.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
          _SectionCard(
            title: 'Описание',
            child: Text(
              breed.description,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          _CharacteristicsGrid(breed: breed),
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
          _SectionCard(
            title: 'Описание',
            child: Text(
              breed.description,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          _CharacteristicsGrid(breed: breed),
        ],
      ),
    );
  }
}

class _CharacteristicsGrid extends StatelessWidget {
  const _CharacteristicsGrid({required this.breed});

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
        return _SectionCard(
          title: item.title,
          child: _Meter(level: item.level),
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

class _Meter extends StatelessWidget {
  const _Meter({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
            height: 12,
            decoration: BoxDecoration(
              color: index < level
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white24,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
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

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF111827),
            Color(0xFF0B1120),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

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
    return CatImage(
      id: json['id'] as String? ?? json['url'] as String? ?? 'cat',
      url: json['url'] as String? ?? '',
      breed: Breed.fromJson(breeds.first as Map<String, dynamic>),
      aspectRatio:
          width != null && height != null && height > 0 ? width / height : null,
    );
  }

  final String id;
  final String url;
  final Breed breed;
  final double? aspectRatio;
}

class CatApiException implements Exception {
  CatApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
}

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
    throw CatApiException(
        'Сервис не прислал котика с породой. Попробуйте ещё раз.');
  }

  Future<List<Breed>> fetchBreeds() async {
    _breedsFuture ??= _loadBreeds();
    return _breedsFuture!;
  }

  Future<List<Breed>> _loadBreeds() async {
    final uri = Uri.parse('$_baseUrl/breeds');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw CatApiException('Код ответа: ${response.statusCode}');
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
        throw CatApiException('Код ответа: ${response.statusCode}');
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
