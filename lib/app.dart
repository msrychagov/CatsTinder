import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/di/app_dependencies.dart';
import 'features/auth/domain/auth_credentials_validator.dart';
import 'features/auth/domain/auth_user.dart';
import 'features/auth/domain/usecases/get_current_user_use_case.dart';
import 'features/auth/domain/usecases/sign_in_use_case.dart';
import 'features/auth/domain/usecases/sign_up_use_case.dart';
import 'features/auth/presentation/auth_flow.dart';
import 'features/cats/presentation/home/cat_home_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.dependencies,
  });

  final AppDependencies dependencies;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.system;
  late final AuthCredentialsValidator _credentialsValidator;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final SignInUseCase _signInUseCase;
  late final SignUpUseCase _signUpUseCase;

  AuthUser? _currentUser;
  bool _onboardingCompleted = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    final dependencies = widget.dependencies;

    _credentialsValidator = AuthCredentialsValidator();
    _getCurrentUserUseCase = GetCurrentUserUseCase(dependencies.authRepository);
    _signInUseCase = SignInUseCase(
      repository: dependencies.authRepository,
      analytics: dependencies.authAnalytics,
      validator: _credentialsValidator,
    );
    _signUpUseCase = SignUpUseCase(
      repository: dependencies.authRepository,
      analytics: dependencies.authAnalytics,
      validator: _credentialsValidator,
      userProfileRepository: dependencies.userProfileRepository,
    );

    _initAppState();
  }

  Future<void> _initAppState() async {
    final dependencies = widget.dependencies;
    final completed = await dependencies.onboardingRepository.isCompleted();
    final user = await _getCurrentUserUseCase();
    final themeMode = dependencies.themeModeRepository.loadThemeMode();

    if (!mounted) {
      return;
    }

    setState(() {
      _mode = themeMode;
      _onboardingCompleted = completed;
      _currentUser = user;
      _isReady = true;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (_mode == mode || !mounted) {
      return;
    }

    setState(() {
      _mode = mode;
    });

    unawaited(widget.dependencies.themeModeRepository.saveThemeMode(mode));
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF59E0B);
    final baseText = GoogleFonts.manropeTextTheme();
    final lightText =
        baseText.apply(bodyColor: Colors.black87, displayColor: Colors.black87);
    final darkText =
        baseText.apply(bodyColor: Colors.white, displayColor: Colors.white);

    return MaterialApp(
      title: 'Кототиндер',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeOutCubic,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light)
                .copyWith(
          surfaceContainerHighest: const Color(0xFFE6E9F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        textTheme: lightText,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FC),
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: darkText,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_onboardingCompleted) {
      return OnboardingPage(
        onFinished: _handleOnboardingFinished,
      );
    }

    if (_currentUser == null) {
      return AuthFlow(
        validator: _credentialsValidator,
        signIn: _signInUseCase,
        signUp: _signUpUseCase,
        onAuthenticated: _handleAuthenticated,
      );
    }

    final currentUser = _currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return CatHomePage(
      catsRepository: widget.dependencies.catsRepository,
      likesRepository: widget.dependencies.likesRepository,
      catAnalytics: widget.dependencies.catAnalytics,
      userId: currentUser.id,
      userEmail: currentUser.email,
      userProfileRepository: widget.dependencies.userProfileRepository,
      onSignOut: _handleSignOut,
      themeMode: _mode,
      onThemeModeSelected: _setThemeMode,
    );
  }

  Future<void> _handleOnboardingFinished() async {
    await widget.dependencies.onboardingRepository.complete();

    if (!mounted) {
      return;
    }

    setState(() {
      _onboardingCompleted = true;
    });
  }

  void _handleAuthenticated(AuthUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _handleSignOut() async {
    await widget.dependencies.authRepository.signOut();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = null;
    });
  }
}
