import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/cats/data/cat_api_service.dart';
import 'features/cats/presentation/home/cat_home_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
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
      themeAnimationDuration: Duration.zero,
      themeAnimationCurve: Curves.linear,
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
      home: CatHomePage(
        service: CatApiService(),
        onToggleTheme: _toggleTheme,
        isDarkMode: _mode == ThemeMode.dark,
      ),
    );
  }
}
