import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/cat_api_service.dart';
import '../../models/cat_image.dart';
import '../detail/cat_detail_page.dart';
import '../widgets/background_gradient.dart';

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
  bool _cardInfoVisible = true;

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
    setState(() => _cardInfoVisible = false);
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => CatDetailPage(cat: cat)),
        )
        .whenComplete(() {
      if (!mounted) return;
      setState(() => _cardInfoVisible = true);
    });
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
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.7);
    final pillBg = onSurface.withValues(alpha: 0.12);
    final pillBorder = onSurface.withValues(alpha: 0.18);
    super.build(context);
    return Stack(
      children: [
        const BackgroundGradient(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Свайпай котиков',
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                    _LikesPill(
                      likes: widget.likedCats.length,
                      bg: pillBg,
                      border: pillBorder,
                      textColor: onSurface,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder:
                          (currentChild, previousChildren) => Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
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
                                  showInfo: _cardInfoVisible,
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
                        color: onSurface.withValues(alpha: 0.08),
                        textColor: onSurface,
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
    this.showInfo = true,
  });

  final CatImage cat;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onTap;
  final bool showInfo;

  @override
  State<_CatCard> createState() => _CatCardState();
}

class _CatCardState extends State<_CatCard>
    with SingleTickerProviderStateMixin {
  static const double _heroRadius = 32;
  static const BorderRadius _heroBorderRadius =
      BorderRadius.all(Radius.circular(_heroRadius));
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
      _offset = Offset(dx, dy.clamp(-80, 80));
      _angle = dx / width * 0.15;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final width = MediaQuery.of(context).size.width;
    const threshold = 0.18;
    final normalized = _offset.dx / width;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final hasVelocity = velocityX.abs() > 800;
    final direction = hasVelocity
        ? velocityX.sign
        : (normalized.abs() > threshold ? normalized.sign : 0);

    if (direction != 0) {
      final target = Offset(direction * width * 1.4, _offset.dy);
      _animateTo(
        target,
        onCompleted: () {
          direction > 0 ? widget.onLike() : widget.onDislike();
          _resetPosition();
        },
      );
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
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final cardBg = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final cardBorder = onSurface.withValues(alpha: 0.08);
    final shadowColor =
        (scheme.brightness == Brightness.dark ? Colors.black : Colors.black54)
            .withValues(alpha: 0.35);
    final placeholderColor = onSurface.withValues(alpha: 0.05);
    final isDark = scheme.brightness == Brightness.dark;
    const infoText = Colors.white;
    final infoMuted = Colors.white.withValues(alpha: 0.8);
    final gradientColors = isDark
        ? [
            Colors.black.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
          ]
        : [
            Colors.black.withValues(alpha: 0.78),
            Colors.black.withValues(alpha: 0.46),
            Colors.transparent,
          ];
    final breed = widget.cat.breed;
    final imageHeight = min(MediaQuery.of(context).size.height * 0.55, 520.0);
    final overlayOpacity = (_offset.dx.abs() / 140).clamp(0.0, 1.0);
    final isLike = _offset.dx > 0;

    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: _angle,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border.all(color: cardBorder),
                  borderRadius: _heroBorderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: _heroBorderRadius,
                  child: Stack(
                    children: [
                      Hero(
                        tag: widget.cat.id,
                        child: ClipRRect(
                          borderRadius: _heroBorderRadius,
                          child: SizedBox(
                            height: imageHeight,
                            width: double.infinity,
                            child: CachedNetworkImage(
                              imageUrl: widget.cat.url,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              placeholder: (context, _) => Container(
                                color: placeholderColor,
                                child: const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              ),
                              errorWidget: (context, _, __) => const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.redAccent),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          ignoring: !widget.showInfo,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: widget.showInfo ? 1 : 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(_heroRadius),
                                  bottomRight: Radius.circular(_heroRadius),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: gradientColors,
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
                                      color: infoText,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${breed.origin} • ${breed.temperament}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: infoMuted,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                    child: ClipRRect(
                      borderRadius: _heroBorderRadius,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikesPill extends StatelessWidget {
  const _LikesPill(
      {required this.likes,
      required this.bg,
      required this.border,
      required this.textColor});

  final int likes;
  final Color bg;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded,
              color: Color(0xFFF472B6), size: 18),
          const SizedBox(width: 6),
          Text(
            '$likes',
            style: TextStyle(
              color: textColor,
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
        style: TextStyle(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.7);
    final bg = onSurface.withValues(alpha: 0.04);
    final border = onSurface.withValues(alpha: 0.08);
    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
      child: Center(
        child: child ??
            CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(muted),
            ),
      ),
    );
  }
}
