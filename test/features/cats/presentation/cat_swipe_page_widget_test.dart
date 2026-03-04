import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_setup_task/features/cats/domain/cat_analytics.dart';
import 'package:flutter_setup_task/features/cats/domain/cats_repository.dart';
import 'package:flutter_setup_task/features/cats/models/breed.dart';
import 'package:flutter_setup_task/features/cats/models/cat_image.dart';
import 'package:flutter_setup_task/features/cats/presentation/swipe/cat_swipe_page.dart';

void main() {
  testWidgets('logs like button tap and button-triggered reaction', (
    tester,
  ) async {
    final analytics = _FakeCatAnalytics();
    final cats = [
      _cat(id: 'cat_1', breedId: 'abys', breedName: 'Abyssinian'),
      _cat(id: 'cat_2', breedId: 'beng', breedName: 'Bengal'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CatSwipePage(
          catsRepository: _FakeCatsRepository(cats),
          analytics: analytics,
          likedCats: const [],
          onLike: (_) {},
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byKey(const Key('like_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(analytics.buttonTapActions, ['like']);
    expect(analytics.reactions, hasLength(1));
    expect(analytics.reactions.single.action, 'like');
    expect(analytics.reactions.single.trigger, 'button');
    expect(analytics.reactions.single.likesCountBefore, 0);
    expect(analytics.reactions.single.likesCountAfter, 1);
    expect(analytics.reactions.single.catId, 'cat_1');
  });

  testWidgets('logs swipe-triggered dislike reaction', (tester) async {
    final analytics = _FakeCatAnalytics();
    final cats = [
      _cat(id: 'cat_1', breedId: 'abys', breedName: 'Abyssinian'),
      _cat(id: 'cat_2', breedId: 'beng', breedName: 'Bengal'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CatSwipePage(
          catsRepository: _FakeCatsRepository(cats),
          analytics: analytics,
          likedCats: const [],
          onLike: (_) {},
        ),
      ),
    );

    await tester.pump();

    await tester.drag(find.text('Abyssinian'), const Offset(-500, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(analytics.buttonTapActions, isEmpty);
    expect(analytics.reactions, hasLength(1));
    expect(analytics.reactions.single.action, 'dislike');
    expect(analytics.reactions.single.trigger, 'swipe');
    expect(analytics.reactions.single.likesCountBefore, 0);
    expect(analytics.reactions.single.likesCountAfter, 0);
    expect(analytics.reactions.single.catId, 'cat_1');
  });

  testWidgets('logs detail open from swipe feed', (tester) async {
    final analytics = _FakeCatAnalytics();

    await tester.pumpWidget(
      MaterialApp(
        home: CatSwipePage(
          catsRepository: _FakeCatsRepository([
            _cat(id: 'cat_1', breedId: 'mcoo', breedName: 'Maine Coon'),
          ]),
          analytics: analytics,
          likedCats: const [],
          onLike: (_) {},
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Maine Coon'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(analytics.detailOpens, hasLength(1));
    expect(analytics.detailOpens.single.source, 'swipe_feed');
    expect(analytics.detailOpens.single.catId, 'cat_1');
  });
}

class _FakeCatsRepository implements CatsRepository {
  _FakeCatsRepository(this._cats);

  final List<CatImage> _cats;
  int _index = 0;

  @override
  Future<List<Breed>> fetchBreeds() async => const [];

  @override
  Future<CatImage> fetchRandomCat() async {
    final safeIndex = _index >= _cats.length ? _cats.length - 1 : _index;
    final cat = _cats[safeIndex];
    _index++;
    return cat;
  }
}

class _FakeCatAnalytics implements CatAnalytics {
  final List<String> buttonTapActions = [];
  final List<_ReactionRecord> reactions = [];
  final List<_DetailOpenRecord> detailOpens = [];

  @override
  Future<void> logActionButtonTap({
    required String action,
    required CatImage cat,
    required int likesCountBefore,
  }) async {
    buttonTapActions.add(action);
  }

  @override
  Future<void> logDetailOpened({
    required String source,
    required CatImage cat,
    required int likesCount,
  }) async {
    detailOpens.add(_DetailOpenRecord(source: source, catId: cat.id));
  }

  @override
  Future<void> logLikedCatRemoved({
    required String source,
    required CatImage cat,
    required int likesCountBefore,
    required int likesCountAfter,
  }) async {}

  @override
  Future<void> logReaction({
    required String action,
    required String trigger,
    required CatImage cat,
    required int likesCountBefore,
    required int likesCountAfter,
  }) async {
    reactions.add(
      _ReactionRecord(
        action: action,
        trigger: trigger,
        catId: cat.id,
        likesCountBefore: likesCountBefore,
        likesCountAfter: likesCountAfter,
      ),
    );
  }
}

class _ReactionRecord {
  const _ReactionRecord({
    required this.action,
    required this.trigger,
    required this.catId,
    required this.likesCountBefore,
    required this.likesCountAfter,
  });

  final String action;
  final String trigger;
  final String catId;
  final int likesCountBefore;
  final int likesCountAfter;
}

class _DetailOpenRecord {
  const _DetailOpenRecord({
    required this.source,
    required this.catId,
  });

  final String source;
  final String catId;
}

CatImage _cat({
  required String id,
  required String breedId,
  required String breedName,
}) {
  return CatImage(
    id: id,
    url: 'https://example.com/$id.jpg',
    breed: Breed(
      id: breedId,
      name: breedName,
      description: 'Описание',
      origin: 'Egypt',
      lifeSpan: '12',
      temperament: 'Active',
      energyLevel: 5,
      affectionLevel: 4,
      intelligence: 5,
      socialNeeds: 3,
    ),
    aspectRatio: 1,
  );
}
