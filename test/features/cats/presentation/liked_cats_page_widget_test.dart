import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_setup_task/features/cats/domain/cat_analytics.dart';
import 'package:flutter_setup_task/features/cats/models/breed.dart';
import 'package:flutter_setup_task/features/cats/models/cat_image.dart';
import 'package:flutter_setup_task/features/cats/presentation/liked/liked_cats_page.dart';

void main() {
  testWidgets('logs detail open from liked list', (tester) async {
    _setPhoneViewport(tester);
    final analytics = _FakeCatAnalytics();
    final likedCats = [_cat(id: 'cat_1', breedId: 'abys', breedName: 'Abyssinian')];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LikedCatsPage(
            analytics: analytics,
            likedCats: likedCats,
            onRemove: (_) {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Abyssinian'));
    await tester.tap(find.text('Abyssinian'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(analytics.detailSources, ['liked_list']);
  });

  testWidgets('logs removal from liked list by button', (tester) async {
    _setPhoneViewport(tester);
    final analytics = _FakeCatAnalytics();
    final likedCats = [_cat(id: 'cat_1', breedId: 'abys', breedName: 'Abyssinian')];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LikedCatsPage(
            analytics: analytics,
            likedCats: likedCats,
            onRemove: (_) {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('liked_remove_button')));
    await tester.tap(find.byKey(const Key('liked_remove_button')));
    await tester.pump();

    expect(analytics.removals, hasLength(1));
    expect(analytics.removals.single.source, 'button');
    expect(analytics.removals.single.likesCountBefore, 1);
    expect(analytics.removals.single.likesCountAfter, 0);
  });
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1290, 2796);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeCatAnalytics implements CatAnalytics {
  final List<String> detailSources = [];
  final List<_RemovalRecord> removals = [];

  @override
  Future<void> logActionButtonTap({
    required String action,
    required CatImage cat,
    required int likesCountBefore,
  }) async {}

  @override
  Future<void> logDetailOpened({
    required String source,
    required CatImage cat,
    required int likesCount,
  }) async {
    detailSources.add(source);
  }

  @override
  Future<void> logLikedCatRemoved({
    required String source,
    required CatImage cat,
    required int likesCountBefore,
    required int likesCountAfter,
  }) async {
    removals.add(
      _RemovalRecord(
        source: source,
        likesCountBefore: likesCountBefore,
        likesCountAfter: likesCountAfter,
      ),
    );
  }

  @override
  Future<void> logReaction({
    required String action,
    required String trigger,
    required CatImage cat,
    required int likesCountBefore,
    required int likesCountAfter,
  }) async {}
}

class _RemovalRecord {
  const _RemovalRecord({
    required this.source,
    required this.likesCountBefore,
    required this.likesCountAfter,
  });

  final String source;
  final int likesCountBefore;
  final int likesCountAfter;
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
