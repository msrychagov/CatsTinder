import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_setup_task/features/auth/domain/user_profile.dart';
import 'package:flutter_setup_task/features/auth/domain/user_profile_repository.dart';
import 'package:flutter_setup_task/features/auth/presentation/profile_page.dart';
import 'package:flutter_setup_task/features/auth/presentation/sign_in_page.dart';
import 'package:flutter_setup_task/features/auth/presentation/sign_up_page.dart';
import 'package:flutter_setup_task/features/auth/domain/auth_credentials_validator.dart';
import 'package:flutter_setup_task/features/onboarding/presentation/onboarding_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('generates README screenshots', (tester) async {
    await _captureScreen(
      tester,
      filePath: 'docs/screenshots/current/onboarding.png',
      child: OnboardingPage(onFinished: () {}),
      settleDuration: const Duration(milliseconds: 800),
    );

    await _captureScreen(
      tester,
      filePath: 'docs/screenshots/current/sign_in.png',
      child: SignInPage(
        validator: AuthCredentialsValidator(),
        onToggleToSignUp: () {},
        onSubmit: (_, __) async {},
      ),
    );

    await _captureScreen(
      tester,
      filePath: 'docs/screenshots/current/sign_up.png',
      child: SignUpPage(
        validator: AuthCredentialsValidator(),
        onToggleToSignIn: () {},
        onSubmit: (_) async {},
      ),
    );

    await _captureScreen(
      tester,
      filePath: 'docs/screenshots/current/profile.png',
      child: ProfilePage(
        userId: 'preview-user',
        userEmail: 'cat@example.com',
        repository: _PreviewUserProfileRepository(),
        onSignOut: () async {},
      ),
      settleDuration: const Duration(milliseconds: 200),
    );
  });
}

Future<void> _captureScreen(
  WidgetTester tester, {
  required String filePath,
  required Widget child,
  Duration settleDuration = const Duration(milliseconds: 100),
}) async {
  final boundaryKey = GlobalKey();
  const size = Size(430, 932);

  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1290, 2796);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: _PreviewApp(child: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(settleDuration);
  await tester.pump(const Duration(milliseconds: 50));

  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('Не удалось найти RepaintBoundary для $filePath');
  }

  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Не удалось сериализовать PNG для $filePath');
  }

  final file = File(filePath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData.buffer.asUint8List());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF59E0B);
    final baseText = GoogleFonts.manropeTextTheme();
    final darkText =
        baseText.apply(bodyColor: Colors.white, displayColor: Colors.white);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
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
      home: child,
    );
  }
}

class _PreviewUserProfileRepository implements UserProfileRepository {
  @override
  Future<UserProfile?> getProfile(String userId) async {
    return const UserProfile(
      description: 'Люблю котиков, теплые пледы и вечерние свайпы.',
      energyLevel: 4,
      intelligence: 5,
      affectionLevel: 4,
      socialNeeds: 3,
      photoPath:
          'data:image/png;base64,'
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAoMBgQd6hwcAAAAASUVORK5CYII=',
    );
  }

  @override
  Future<UserProfile> saveProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    return profile;
  }
}
