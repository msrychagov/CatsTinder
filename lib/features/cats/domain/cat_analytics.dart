import '../models/cat_image.dart';

abstract class CatAnalytics {
  Future<void> logActionButtonTap({
    required String action,
    required CatImage cat,
    required int likesCountBefore,
  });

  Future<void> logReaction({
    required String action,
    required String trigger,
    required CatImage cat,
    required int likesCountBefore,
    required int likesCountAfter,
  });

  Future<void> logDetailOpened({
    required String source,
    required CatImage cat,
    required int likesCount,
  });

  Future<void> logLikedCatRemoved({
    required String source,
    required CatImage cat,
    required int likesCountBefore,
    required int likesCountAfter,
  });
}
