import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';

class FirebaseUserProfileRepository implements UserProfileRepository {
  FirebaseUserProfileRepository(
    this._firestore,
    this._storage,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('user_profiles');

  @override
  Future<UserProfile> saveProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    final photoPath = await _resolvePhotoPath(
      userId: userId,
      currentValue: profile.photoPath,
    );

    final savedProfile = profile.copyWith(
      description: profile.description.trim(),
      photoPath: photoPath,
    );

    await _profiles.doc(userId).set(
          savedProfile.toJson(),
          SetOptions(merge: true),
        );
    return savedProfile;
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final snapshot = await _profiles.doc(userId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return UserProfile.fromJson(data);
  }

  Future<String> _resolvePhotoPath({
    required String userId,
    required String currentValue,
  }) async {
    final value = currentValue.trim();
    if (value.isEmpty) {
      return value;
    }

    final uri = Uri.tryParse(value);
    final isRemote = uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
    final isInlineData = uri != null && uri.scheme.toLowerCase() == 'data';
    if (isRemote || isInlineData) {
      return value;
    }

    final file = File(value);
    if (!await file.exists()) {
      throw StateError('Локальное фото не найдено. Выберите фото заново.');
    }

    final extension = _normalizedExtension(value);
    final fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}$extension';

    final path = 'user_profiles/$userId/$fileName';
    final downloadToken = _generateDownloadToken();
    final metadata = SettableMetadata(
      contentType: _contentType(extension),
      customMetadata: {
        'firebaseStorageDownloadTokens': downloadToken,
      },
    );

    final candidates = <FirebaseStorage>[_storage];
    final fallbackStorage = _fallbackStorage();
    if (fallbackStorage != null &&
        fallbackStorage.bucket.replaceFirst('gs://', '') !=
            _storage.bucket.replaceFirst('gs://', '')) {
      candidates.add(fallbackStorage);
    }

    Object? lastError;
    for (final storage in candidates) {
      final ref = storage.ref().child(path);
      try {
        await ref.putFile(file, metadata);
        return _downloadUrlAfterUpload(
          ref: ref,
          path: path,
          downloadToken: downloadToken,
        );
      } on FirebaseException catch (error) {
        lastError = error;
        if (!_shouldRetryWithFallback(error)) {
          lastError = error;
          break;
        }
      }
    }

    final inlinePhoto = await _buildInlinePhotoData(
      file: file,
      extension: extension,
    );
    if (inlinePhoto != null) {
      return inlinePhoto;
    }

    if (lastError is FirebaseException) {
      throw lastError;
    }
    throw StateError('Не удалось загрузить фото профиля в Storage');
  }

  Future<String> _downloadUrlAfterUpload({
    required Reference ref,
    required String path,
    required String downloadToken,
  }) async {
    try {
      return await _getDownloadUrlWithRetry(ref);
    } on FirebaseException catch (error) {
      // On some setups getDownloadURL may fail right after upload.
      // Fallback to deterministic tokenized URL built from path.
      if (error.code == 'object-not-found' ||
          error.code == 'unauthorized' ||
          error.code == 'permission-denied' ||
          error.code == 'unauthenticated') {
        return _buildTokenizedDownloadUrl(
          bucket: ref.bucket,
          path: path,
          downloadToken: downloadToken,
        );
      }
      rethrow;
    }
  }

  FirebaseStorage? _fallbackStorage() {
    final bucket = _storage.bucket.replaceFirst('gs://', '');
    String? altBucket;
    if (bucket.endsWith('.firebasestorage.app')) {
      altBucket = bucket.replaceFirst('.firebasestorage.app', '.appspot.com');
    } else if (bucket.endsWith('.appspot.com')) {
      altBucket = bucket.replaceFirst('.appspot.com', '.firebasestorage.app');
    }
    if (altBucket == null) {
      return null;
    }
    return FirebaseStorage.instanceFor(
      app: _storage.app,
      bucket: 'gs://$altBucket',
    );
  }

  bool _shouldRetryWithFallback(FirebaseException error) {
    return error.code == 'object-not-found' ||
        error.code == 'bucket-not-found' ||
        error.code == 'project-not-found';
  }

  Future<String> _getDownloadUrlWithRetry(Reference ref) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await ref.getDownloadURL();
      } catch (error) {
        lastError = error;
        if (error is! FirebaseException || error.code != 'object-not-found') {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }

    if (lastError is FirebaseException) {
      throw lastError;
    }
    throw StateError('Не удалось получить URL фото после загрузки');
  }

  String _buildTokenizedDownloadUrl({
    required String bucket,
    required String path,
    required String downloadToken,
  }) {
    final normalizedBucket = bucket.replaceFirst('gs://', '');
    final encodedPath = Uri.encodeComponent(path);
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '$normalizedBucket/o/$encodedPath?alt=media&token=$downloadToken';
  }

  Future<String?> _buildInlinePhotoData({
    required File file,
    required String extension,
  }) async {
    final bytes = await file.readAsBytes();
    // Keep enough headroom for the rest of the Firestore document.
    if (bytes.length > 700 * 1024) {
      return null;
    }
    final base64 = base64Encode(bytes);
    return 'data:${_contentType(extension)};base64,$base64';
  }

  String _generateDownloadToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _normalizedExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) {
      return '.jpg';
    }
    final extension = path.substring(dotIndex).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
      case '.heic':
        return extension;
      default:
        return '.jpg';
    }
  }

  String _contentType(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
