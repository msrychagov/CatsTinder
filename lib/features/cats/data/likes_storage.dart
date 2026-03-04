import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cat_image.dart';

class LikesStorage {
  static const _legacyKey = 'liked_cats';

  String _keyForUser(String userId) => 'liked_cats_$userId';

  Future<List<CatImage>> loadLikes(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_keyForUser(userId)) ?? prefs.getString(_legacyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = json.decode(raw) as List<dynamic>;
      return data
          .map((e) => CatImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLikes(String userId, List<CatImage> cats) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        json.encode(cats.map((cat) => cat.toJson()).toList(growable: false));
    await prefs.setString(_keyForUser(userId), encoded);
  }
}
