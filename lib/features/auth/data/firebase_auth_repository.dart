import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebaseAuth);

  final fb.FirebaseAuth _firebaseAuth;

  AuthUser? _mapUser(fb.User? user) {
    if (user == null) return null;
    final email = user.email;
    if (email == null) return null;
    return AuthUser(id: user.uid, email: email);
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AuthUser?> currentUser() async {
    return _mapUser(_firebaseAuth.currentUser);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = _mapUser(credential.user);
    if (user == null) {
      throw StateError('Не удалось получить пользователя после входа');
    }
    return user;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = _mapUser(credential.user);
    if (user == null) {
      throw StateError('Не удалось получить пользователя после регистрации');
    }
    return user;
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}
