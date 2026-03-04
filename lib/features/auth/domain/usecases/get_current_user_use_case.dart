import '../auth_repository.dart';
import '../auth_user.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser?> call() {
    return _repository.currentUser();
  }
}
