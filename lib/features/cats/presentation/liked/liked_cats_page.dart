import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/cat_image.dart';
import '../detail/cat_detail_page.dart';
import '../widgets/background_gradient.dart';

class LikedCatsPage extends StatefulWidget {
  const LikedCatsPage({
    super.key,
    required this.likedCats,
    required this.onRemove,
  });

  final List<CatImage> likedCats;
  final ValueChanged<CatImage> onRemove;

  @override
  State<LikedCatsPage> createState() => _LikedCatsPageState();
}

class _LikedCatsPageState extends State<LikedCatsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.7);
    final cardBg = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final cardBorder = onSurface.withValues(alpha: 0.08);
    final placeholder = onSurface.withValues(alpha: 0.06);
    final liked = widget.likedCats.reversed.toList();
    if (liked.isEmpty) {
      return Stack(
        children: [
          const BackgroundGradient(),
          Center(
            child: Text(
              'Пока нет лайкнутых котиков',
              style: TextStyle(color: muted),
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        const BackgroundGradient(),
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemBuilder: (context, index) {
            final cat = liked[index];
            return Dismissible(
              key: ValueKey(cat.id),
              direction: DismissDirection.endToStart,
              background: _DismissBackground(color: scheme.error),
              onDismissed: (_) => widget.onRemove(cat),
              child: _LikedCard(
                cat: cat,
                onRemove: () => widget.onRemove(cat),
                bg: cardBg,
                border: cardBorder,
                placeholder: placeholder,
                textColor: onSurface,
                mutedColor: muted,
              ),
            );
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
  const _LikedCard({
    required this.cat,
    required this.onRemove,
    required this.bg,
    required this.border,
    required this.placeholder,
    required this.textColor,
    required this.mutedColor,
  });

  final CatImage cat;
  final VoidCallback onRemove;
  final Color bg;
  final Color border;
  final Color placeholder;
  final Color textColor;
  final Color mutedColor;

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
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Stack(
          children: [
            Column(
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
                        color: placeholder,
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
                        style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${breed.origin} • ${breed.temperament}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: mutedColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                ),
                icon: Icon(Icons.delete_outline, color: textColor),
                onPressed: onRemove,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );
  }
}
