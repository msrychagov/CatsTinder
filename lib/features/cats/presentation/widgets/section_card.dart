import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final border = onSurface.withValues(alpha: 0.1);
    final bg = scheme.surfaceContainerHighest.withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.06 : 0.5);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                TextStyle(color: onSurface, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class Meter extends StatelessWidget {
  const Meter({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = scheme.primary;
    final inactive = scheme.onSurface.withValues(alpha: 0.24);
    return Row(
      children: List.generate(
        5,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
            height: 12,
            decoration: BoxDecoration(
              color: index < level ? active : inactive,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
