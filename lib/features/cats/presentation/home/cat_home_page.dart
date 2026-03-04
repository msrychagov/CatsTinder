import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_setup_task/features/auth/domain/user_profile_repository.dart';
import 'package:flutter_setup_task/features/auth/presentation/profile_page.dart';

import '../../domain/cat_analytics.dart';
import '../../domain/cats_repository.dart';
import '../../domain/likes_repository.dart';
import '../../models/cat_image.dart';
import '../breeds/breed_list_page.dart';
import '../liked/liked_cats_page.dart';
import '../swipe/cat_swipe_page.dart';

class CatHomePage extends StatefulWidget {
  const CatHomePage({
    super.key,
    required this.catsRepository,
    required this.likesRepository,
    required this.catAnalytics,
    required this.userId,
    required this.userEmail,
    required this.userProfileRepository,
    required this.onSignOut,
    required this.themeMode,
    required this.onThemeModeSelected,
  });

  final CatsRepository catsRepository;
  final LikesRepository likesRepository;
  final CatAnalytics catAnalytics;
  final String userId;
  final String userEmail;
  final UserProfileRepository userProfileRepository;
  final Future<void> Function() onSignOut;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;

  @override
  State<CatHomePage> createState() => _CatHomePageState();
}

class _CatHomePageState extends State<CatHomePage> {
  final List<CatImage> _likedCats = [];

  @override
  void initState() {
    super.initState();
    _restoreLikes();
  }

  void _addLike(CatImage cat) {
    final exists = _likedCats.any((liked) => liked.id == cat.id);
    if (exists) {
      return;
    }

    late final List<CatImage> snapshot;
    setState(() {
      _likedCats.add(cat);
      snapshot = List<CatImage>.from(_likedCats);
    });
    unawaited(_persistLikes(snapshot));
  }

  void _removeLike(CatImage cat) {
    late final List<CatImage> snapshot;
    setState(() {
      _likedCats.removeWhere((liked) => liked.id == cat.id);
      snapshot = List<CatImage>.from(_likedCats);
    });
    unawaited(_persistLikes(snapshot));
  }

  Future<void> _restoreLikes() async {
    try {
      final saved = await widget.likesRepository.loadLikes(widget.userId);
      if (!mounted || saved.isEmpty) {
        return;
      }

      setState(() {
        _likedCats
          ..clear()
          ..addAll(saved);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось загрузить лайки из облака.'),
        ),
      );
    }
  }

  Future<void> _persistLikes(List<CatImage> snapshot) async {
    try {
      await widget.likesRepository.saveLikes(
        userId: widget.userId,
        cats: snapshot,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить лайки в облако.'),
        ),
      );
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          userId: widget.userId,
          userEmail: widget.userEmail,
          repository: widget.userProfileRepository,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
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
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: _openProfile,
            ),
            PopupMenuButton<ThemeMode>(
              tooltip: 'Тема',
              initialValue: widget.themeMode,
              onSelected: widget.onThemeModeSelected,
              icon: Icon(_themeModeIcon(widget.themeMode)),
              itemBuilder: (context) => [
                _themeModeItem(
                  mode: ThemeMode.light,
                  label: 'Светлая',
                  icon: Icons.light_mode_outlined,
                ),
                _themeModeItem(
                  mode: ThemeMode.dark,
                  label: 'Темная',
                  icon: Icons.dark_mode_outlined,
                ),
                _themeModeItem(
                  mode: ThemeMode.system,
                  label: 'Системная',
                  icon: Icons.brightness_auto,
                ),
              ],
            ),
          ],
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
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CatSwipePage(
              catsRepository: widget.catsRepository,
              analytics: widget.catAnalytics,
              likedCats: _likedCats,
              onLike: _addLike,
            ),
            BreedListPage(catsRepository: widget.catsRepository),
            LikedCatsPage(
              analytics: widget.catAnalytics,
              likedCats: _likedCats,
              onRemove: _removeLike,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ThemeMode> _themeModeItem({
    required ThemeMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = widget.themeMode == mode;
    return PopupMenuItem<ThemeMode>(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (isSelected) const Icon(Icons.check, size: 18),
        ],
      ),
    );
  }

  IconData _themeModeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto,
    };
  }
}
