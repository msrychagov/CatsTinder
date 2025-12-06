import 'package:flutter/material.dart';

import '../../data/cat_api_service.dart';
import '../../data/likes_storage.dart';
import '../../models/cat_image.dart';
import '../breeds/breed_list_page.dart';
import '../liked/liked_cats_page.dart';
import '../swipe/cat_swipe_page.dart';

class CatHomePage extends StatefulWidget {
  const CatHomePage({super.key, required this.service});

  final CatApiService service;

  @override
  State<CatHomePage> createState() => _CatHomePageState();
}

class _CatHomePageState extends State<CatHomePage> {
  final LikesStorage _storage = LikesStorage();
  final List<CatImage> _likedCats = [];

  @override
  void initState() {
    super.initState();
    _restoreLikes();
  }

  void _addLike(CatImage cat) {
    final exists = _likedCats.any((c) => c.id == cat.id);
    if (exists) return;
    setState(() => _likedCats.add(cat));
    _storage.saveLikes(_likedCats);
  }

  Future<void> _restoreLikes() async {
    final saved = await _storage.loadLikes();
    if (!mounted || saved.isEmpty) return;
    setState(() {
      _likedCats
        ..clear()
        ..addAll(saved);
    });
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
          physics: const NeverScrollableScrollPhysics(),
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
