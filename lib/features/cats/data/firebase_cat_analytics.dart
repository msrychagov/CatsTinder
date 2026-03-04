import 'package:firebase_analytics/firebase_analytics.dart';

import '../domain/cat_analytics.dart';
import '../models/cat_image.dart';

class FirebaseCatAnalytics implements CatAnalytics {
  const FirebaseCatAnalytics(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logActionButtonTap({
    required String action,
    required CatImage cat,
    required int likesCountBefore,
  }) {
    return _analytics.logEvent(
      name: 'cat_action_button_tap',
      parameters: _baseParameters(
        cat: cat,
        likesCountBefore: likesCountBefore,
      )..addAll({
          'action': _normalizeToken(action),
        }),
    );
  }

  @override
  Future<void> logReaction({
    required String action,
    required String trigger,
    required CatImage cat,
    required int likesCountBefore,
    required int likesCountAfter,
  }) {
    return _analytics.logEvent(
      name: 'cat_reaction',
      parameters: _baseParameters(
        cat: cat,
        likesCountBefore: likesCountBefore,
      )..addAll({
          'action': _normalizeToken(action),
          'trigger': _normalizeToken(trigger),
          'likes_count_after': _normalizeCount(likesCountAfter),
        }),
    );
  }

  @override
  Future<void> logDetailOpened({
    required String source,
    required CatImage cat,
    required int likesCount,
  }) {
    return _analytics.logEvent(
      name: 'cat_detail_open',
      parameters: _baseParameters(
        cat: cat,
        likesCountBefore: likesCount,
      )..addAll({
          'source': _normalizeToken(source),
        }),
    );
  }

  @override
  Future<void> logLikedCatRemoved({
    required String source,
    required CatImage cat,
    required int likesCountBefore,
    required int likesCountAfter,
  }) {
    return _analytics.logEvent(
      name: 'liked_cat_remove',
      parameters: _baseParameters(
        cat: cat,
        likesCountBefore: likesCountBefore,
      )..addAll({
          'source': _normalizeToken(source),
          'likes_count_after': _normalizeCount(likesCountAfter),
        }),
    );
  }

  Map<String, Object> _baseParameters({
    required CatImage cat,
    required int likesCountBefore,
  }) {
    final breed = cat.breed;
    return {
      'cat_id': _normalizeToken(cat.id),
      'breed_id': _normalizeToken(breed.id),
      'breed_name': _normalizeValue(breed.name),
      'origin': _normalizeValue(breed.origin),
      'energy_level': breed.energyLevel,
      'intelligence': breed.intelligence,
      'affection_level': breed.affectionLevel,
      'social_needs': breed.socialNeeds,
      'likes_count_before': _normalizeCount(likesCountBefore),
    };
  }

  int _normalizeCount(int value) {
    if (value < 0) {
      return 0;
    }
    return value;
  }

  String _normalizeToken(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    if (normalized.isEmpty) {
      return 'unknown';
    }
    return normalized.substring(0, normalized.length > 40 ? 40 : normalized.length);
  }

  String _normalizeValue(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'unknown';
    }
    return normalized.substring(0, normalized.length > 100 ? 100 : normalized.length);
  }
}
