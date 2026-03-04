import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/shared_prefs_theme_mode_repository.dart';
import '../../features/auth/data/firebase_auth_analytics.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/data/firebase_user_profile_repository.dart';
import '../../features/auth/domain/auth_analytics.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/user_profile_repository.dart';
import '../../features/cats/data/cat_api_service.dart';
import '../../features/cats/data/firebase_cat_analytics.dart';
import '../../features/cats/data/firebase_likes_repository.dart';
import '../../features/cats/data/likes_storage.dart';
import '../../features/cats/data/the_cat_api_cats_repository.dart';
import '../../features/cats/domain/cat_analytics.dart';
import '../../features/cats/domain/cats_repository.dart';
import '../../features/cats/domain/likes_repository.dart';
import '../../features/onboarding/data/shared_prefs_onboarding_repository.dart';
import '../../features/onboarding/domain/onboarding_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.authAnalytics,
    required this.themeModeRepository,
    required this.userProfileRepository,
    required this.onboardingRepository,
    required this.catsRepository,
    required this.likesRepository,
    required this.catAnalytics,
  });

  final AuthRepository authRepository;
  final AuthAnalytics authAnalytics;
  final SharedPrefsThemeModeRepository themeModeRepository;
  final UserProfileRepository userProfileRepository;
  final OnboardingRepository onboardingRepository;
  final CatsRepository catsRepository;
  final LikesRepository likesRepository;
  final CatAnalytics catAnalytics;
}

Future<AppDependencies> buildAppDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  final authRepository = FirebaseAuthRepository(fb.FirebaseAuth.instance);
  final authAnalytics = FirebaseAuthAnalytics(FirebaseAnalytics.instance);
  final themeModeRepository = SharedPrefsThemeModeRepository(prefs);
  final storageBucket = Firebase.app().options.storageBucket;
  final normalizedBucket = _normalizeStorageBucket(storageBucket);
  final storage = normalizedBucket == null
      ? FirebaseStorage.instance
      : FirebaseStorage.instanceFor(bucket: normalizedBucket);
  final userProfileRepository = FirebaseUserProfileRepository(
    FirebaseFirestore.instance,
    storage,
  );

  final onboardingRepository = SharedPrefsOnboardingRepository(prefs);

  final catApiService = CatApiService();
  final likesStorage = LikesStorage();
  final catsRepository = TheCatApiCatsRepository(catApiService);
  final likesRepository = FirebaseLikesRepository(
    FirebaseFirestore.instance,
    localStorage: likesStorage,
  );
  final catAnalytics = FirebaseCatAnalytics(FirebaseAnalytics.instance);

  return AppDependencies(
    authRepository: authRepository,
    authAnalytics: authAnalytics,
    themeModeRepository: themeModeRepository,
    userProfileRepository: userProfileRepository,
    onboardingRepository: onboardingRepository,
    catsRepository: catsRepository,
    likesRepository: likesRepository,
    catAnalytics: catAnalytics,
  );
}

String? _normalizeStorageBucket(String? rawBucket) {
  if (rawBucket == null) {
    return null;
  }
  final value = rawBucket.trim();
  if (value.isEmpty) {
    return null;
  }

  final withoutScheme =
      value.startsWith('gs://') ? value.replaceFirst('gs://', '') : value;
  return 'gs://$withoutScheme';
}
