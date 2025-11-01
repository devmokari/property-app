import 'package:flutter/material.dart';

import 'address_lookup/address_lookup_page.dart';

void main() {
  runApp(const HomegptApp());
}

class HomegptApp extends StatelessWidget {
  const HomegptApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.light,
    );

    final baseTheme = ThemeData(
      colorScheme: baseColorScheme,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'HomeGPT',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF3F5F7),
        textTheme: baseTheme.textTheme.copyWith(
          headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B3A2C),
          ),
          titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B3A2C),
          ),
          bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF35524A),
          ),
          bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4C6A58),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: baseColorScheme.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: baseColorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: baseColorScheme.primary.withOpacity(0.9)),
          hintStyle: baseTheme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF7B8F86),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: baseColorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: baseColorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: baseColorScheme.primary, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: baseColorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            elevation: 2,
          ),
        ),
      ),
      home: const AddressLookupPage(),
    );
  }
}
