import 'user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile> saveProfile({
    required String userId,
    required UserProfile profile,
  });

  Future<UserProfile?> getProfile(String userId);
}
