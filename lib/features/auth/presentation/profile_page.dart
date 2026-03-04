import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';
import 'widgets/profile_description_field.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.repository,
    required this.onSignOut,
  });

  final String userId;
  final String userEmail;
  final UserProfileRepository repository;
  final Future<void> Function() onSignOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  bool _isSigningOut = false;

  String? _photoPath;

  double _energyLevel = 3;
  double _intelligence = 3;
  double _affectionLevel = 3;
  double _socialNeeds = 3;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.repository.getProfile(widget.userId);
    if (!mounted) {
      return;
    }

    if (profile != null) {
      _descriptionController.text = profile.description;
      _photoPath = profile.photoPath.isEmpty ? null : profile.photoPath;
      _energyLevel = profile.energyLevel.clamp(1, 5).toDouble();
      _intelligence = profile.intelligence.clamp(1, 5).toDouble();
      _affectionLevel = profile.affectionLevel.clamp(1, 5).toDouble();
      _socialNeeds = profile.socialNeeds.clamp(1, 5).toDouble();
    }

    setState(() => _isLoading = false);
  }

  String? _validateDescription(String? value) {
    // Description is optional.
    return null;
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto || _isSaving || _isSigningOut) {
      return;
    }

    setState(() => _isPickingPhoto = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 512,
      );
      if (file == null || !mounted) {
        return;
      }
      setState(() => _photoPath = file.path);
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final photoPath = _photoPath;
    if (photoPath == null || photoPath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте фото профиля')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profile = UserProfile(
        description: _descriptionController.text.trim(),
        energyLevel: _energyLevel.round(),
        intelligence: _intelligence.round(),
        affectionLevel: _affectionLevel.round(),
        socialNeeds: _socialNeeds.round(),
        photoPath: photoPath,
      );

      final savedProfile = await widget.repository.saveProfile(
        userId: widget.userId,
        profile: profile,
      );

      if (mounted) {
        setState(() {
          _photoPath =
              savedProfile.photoPath.isEmpty ? null : savedProfile.photoPath;
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранен')),
      );
    } catch (error) {
      debugPrint('Profile save failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_saveErrorMessage(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _saveErrorMessage(Object error) {
    if (error is FirebaseException) {
      if (error.plugin == 'firebase_storage') {
        if (error.code == 'unauthorized' || error.code == 'permission-denied') {
          return 'Нет доступа к Firebase Storage. Проверьте Storage Rules.';
        }
        if (error.code == 'no-default-bucket' ||
            error.code == 'bucket-not-found' ||
            error.code == 'project-not-found') {
          return 'Storage bucket не настроен. Включите Firebase Storage в консоли.';
        }
        if (error.code == 'object-not-found') {
          return 'Не удалось получить URL загруженного фото. Проверьте Storage Rules.';
        }
        if (error.code == 'unauthenticated') {
          return 'Сессия истекла. Войдите в аккаунт заново.';
        }
        return 'Не удалось загрузить фото в облако.';
      }
      if (error.plugin == 'cloud_firestore') {
        if (error.code == 'permission-denied') {
          return 'Нет доступа к Firestore. Проверьте Firestore Rules.';
        }
        return 'Не удалось сохранить профиль в облако.';
      }
    }

    if (error is StateError) {
      return error.message.toString();
    }
    return 'Не удалось сохранить профиль. Попробуйте еще раз.';
  }

  ImageProvider<Object>? _buildPhotoProvider(String? photoPath) {
    final value = photoPath?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    final isRemote = uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
    if (isRemote) {
      return NetworkImage(value);
    }

    final isInlineData = uri != null && uri.scheme.toLowerCase() == 'data';
    if (isInlineData) {
      final data = Uri.parse(value).data;
      if (data == null) {
        return null;
      }
      return MemoryImage(data.contentAsBytes());
    }

    final file = File(value);
    if (!file.existsSync()) {
      return null;
    }
    return FileImage(file);
  }

  Future<void> _signOut() async {
    if (_isSaving || _isPickingPhoto || _isSigningOut) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Выйти из аккаунта?'),
            content:
                const Text('После выхода нужно будет снова выполнить вход.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Выйти'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isSigningOut = true);
    try {
      await widget.onSignOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось выйти из аккаунта. Попробуйте еще раз.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final photoPath = _photoPath;
    final avatarProvider = _buildPhotoProvider(photoPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickPhoto,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor:
                                    onSurface.withValues(alpha: 0.12),
                                backgroundImage: avatarProvider,
                                child: avatarProvider == null
                                    ? Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 34,
                                        color:
                                            onSurface.withValues(alpha: 0.75),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: (_isSaving || _isSigningOut)
                                ? null
                                : _pickPhoto,
                            icon: _isPickingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_outlined),
                            label: const Text('Изменить фото'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Email',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.userEmail,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ProfileDescriptionField(
                            controller: _descriptionController,
                            validator: _validateDescription,
                          ),
                          const SizedBox(height: 18),
                          _TraitSlider(
                            title: 'Энергия',
                            value: _energyLevel,
                            onChanged: (value) {
                              setState(() => _energyLevel = value);
                            },
                          ),
                          _TraitSlider(
                            title: 'Интеллект',
                            value: _intelligence,
                            onChanged: (value) {
                              setState(() => _intelligence = value);
                            },
                          ),
                          _TraitSlider(
                            title: 'Ласковость',
                            value: _affectionLevel,
                            onChanged: (value) {
                              setState(() => _affectionLevel = value);
                            },
                          ),
                          _TraitSlider(
                            title: 'Социальность',
                            value: _socialNeeds,
                            onChanged: (value) {
                              setState(() => _socialNeeds = value);
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: (_isSaving || _isSigningOut)
                                ? null
                                : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Сохранить'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                (_isSaving || _isSigningOut) ? null : _signOut,
                            icon: _isSigningOut
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.logout),
                            label: Text(
                              _isSigningOut
                                  ? 'Выходим...'
                                  : 'Выйти из аккаунта',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(
                                color: theme.colorScheme.error
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TraitSlider extends StatelessWidget {
  const _TraitSlider({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${value.round()}/5',
              style: theme.textTheme.labelLarge?.copyWith(
                color: onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
