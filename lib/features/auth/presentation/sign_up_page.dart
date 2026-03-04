import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/auth_credentials_validator.dart';
import '../domain/user_profile.dart';
import 'widgets/profile_description_field.dart';

typedef SignUpSubmit = Future<void> Function(SignUpFormData formData);
typedef PickPhotoPath = Future<String?> Function();

class SignUpFormData {
  const SignUpFormData({
    required this.email,
    required this.password,
    required this.description,
    required this.energyLevel,
    required this.intelligence,
    required this.affectionLevel,
    required this.socialNeeds,
    required this.photoPath,
  });

  final String email;
  final String password;
  final String description;
  final int energyLevel;
  final int intelligence;
  final int affectionLevel;
  final int socialNeeds;
  final String photoPath;

  UserProfile toUserProfile() {
    return UserProfile(
      description: description,
      energyLevel: energyLevel,
      intelligence: intelligence,
      affectionLevel: affectionLevel,
      socialNeeds: socialNeeds,
      photoPath: photoPath,
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    required this.validator,
    required this.onToggleToSignIn,
    required this.onSubmit,
    this.pickPhotoPath,
  });

  final AuthCredentialsValidator validator;
  final VoidCallback onToggleToSignIn;
  final SignUpSubmit onSubmit;
  final PickPhotoPath? pickPhotoPath;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isPickingPhoto = false;

  String? _photoPath;

  double _energyLevel = 3;
  double _intelligence = 3;
  double _affectionLevel = 3;
  double _socialNeeds = 3;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateRepeatPassword(String? value) {
    final repeatPassword = value ?? '';
    if (repeatPassword.isEmpty) {
      return 'Повторите пароль';
    }
    if (repeatPassword != _passwordController.text) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    // Description is optional.
    return null;
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto || _isLoading) {
      return;
    }

    setState(() => _isPickingPhoto = true);
    try {
      final pickedPath = await _pickPhotoPath();
      if (pickedPath == null || pickedPath.trim().isEmpty || !mounted) {
        return;
      }
      setState(() => _photoPath = pickedPath);
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<String?> _pickPhotoPath() async {
    final customPicker = widget.pickPhotoPath;
    if (customPicker != null) {
      return customPicker();
    }

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );
    return file?.path;
  }

  Future<void> _submit() async {
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

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        SignUpFormData(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          description: _descriptionController.text.trim(),
          energyLevel: _energyLevel.round(),
          intelligence: _intelligence.round(),
          affectionLevel: _affectionLevel.round(),
          socialNeeds: _socialNeeds.round(),
          photoPath: photoPath,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurface = scheme.onSurface;
    final photoPath = _photoPath;
    final avatarProvider = _buildPhotoProvider(photoPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Создайте аккаунт 😺',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Заполните анкету для вашего профиля.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor:
                                  onSurface.withValues(alpha: 0.12),
                              backgroundImage: avatarProvider,
                              child: avatarProvider == null
                                  ? Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 34,
                                      color: onSurface.withValues(alpha: 0.75),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _pickPhoto,
                            icon: _isPickingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_outlined),
                            label: const Text('Добавить фото'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('sign_up_email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: widget.validator.validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('sign_up_password_field'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: widget.validator.validatePassword,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('sign_up_repeat_password_field'),
                      controller: _repeatPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Повторите пароль',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: _validateRepeatPassword,
                    ),
                    const SizedBox(height: 14),
                    ProfileDescriptionField(
                      fieldKey: const Key('sign_up_description_field'),
                      controller: _descriptionController,
                      validator: _validateDescription,
                    ),
                    const SizedBox(height: 18),
                    _TraitSlider(
                      title: 'Энергия',
                      value: _energyLevel,
                      onChanged: (value) =>
                          setState(() => _energyLevel = value),
                    ),
                    _TraitSlider(
                      title: 'Интеллект',
                      value: _intelligence,
                      onChanged: (value) =>
                          setState(() => _intelligence = value),
                    ),
                    _TraitSlider(
                      title: 'Ласковость',
                      value: _affectionLevel,
                      onChanged: (value) =>
                          setState(() => _affectionLevel = value),
                    ),
                    _TraitSlider(
                      title: 'Социальность',
                      value: _socialNeeds,
                      onChanged: (value) =>
                          setState(() => _socialNeeds = value),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const Key('sign_up_submit_button'),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зарегистрироваться'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onToggleToSignIn,
                      child: const Text('У меня уже есть аккаунт'),
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
