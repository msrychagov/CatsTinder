import 'package:flutter/material.dart';

typedef OnboardingFinished = void Function();

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onFinished,
  });

  final OnboardingFinished onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    (
      title: 'Свайпай котиков',
      description:
          'Лайкай и дизлайкай котиков свайпами, как в тиндерах, и находи самых милых.',
    ),
    (
      title: 'Узнавай о породах',
      description:
          'Смотри детали породы, характеристики и фото, чтобы лучше понимать своих фаворитов.',
    ),
    (
      title: 'Сохраняй любимчиков',
      description:
          'Список лайкнутых котиков всегда под рукой — возвращайся к ним в любой момент.',
    ),
  ];

  void _onNext() {
    if (_currentPage == _pages.length - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final progress = (_currentPage - index).toDouble().abs();
                  final scale = (1.0 - progress * 0.15).clamp(0.8, 1.0);
                  final opacity = (1.0 - progress * 0.5).clamp(0.3, 1.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: scale,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: AnimatedOpacity(
                            opacity: opacity,
                            duration: const Duration(milliseconds: 250),
                            child: _AnimatedCat(index: index),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyLarge?.color
                                ?.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final selected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: selected ? 24 : 8,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onNext,
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Начать' : 'Далее',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPage < _pages.length - 1)
              TextButton(
                onPressed: widget.onFinished,
                child: const Text('Пропустить'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCat extends StatelessWidget {
  const _AnimatedCat({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (index) {
      0 => theme.colorScheme.primary,
      1 => theme.colorScheme.tertiary,
      _ => theme.colorScheme.secondary,
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedOpacity = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, (1 - value) * 40),
          child: Transform.scale(
            scale: 0.9 + value * 0.1,
            child: Opacity(
              opacity: clampedOpacity,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        height: 220,
        width: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.4),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.pets,
            size: 120,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
