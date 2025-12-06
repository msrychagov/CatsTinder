import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/cats/data/cat_api_service.dart';
import 'features/cats/presentation/home/cat_home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF59E0B);
    return MaterialApp(
      title: 'Кототиндер',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.manropeTextTheme(),
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
      ),
    );
  }
}
