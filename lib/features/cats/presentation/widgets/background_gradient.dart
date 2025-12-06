import 'package:flutter/material.dart';

class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF0F172A),
                  Color(0xFF111827),
                  Color(0xFF0B1120),
                ]
              : const [
                  Color(0xFFF2F4F7),
                  Color(0xFFE5E7EB),
                  Color(0xFFEFF3FB),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
