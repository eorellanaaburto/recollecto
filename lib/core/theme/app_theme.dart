import 'package:flutter/material.dart';

class AppTheme {
  // Paleta "cream anime 90s"
  static const Color primaryColor = Color(0xFFB88CCB); // lavanda suave
  static const Color secondaryColor = Color(0xFFE7A7A0); // rosa durazno
  static const Color accentColor = Color(0xFFA9C9D9); // azul polvo
  static const Color mintColor = Color(0xFFC8D9C4); // menta suave

  static const Color darkColor = Color(0xFF2E2A33);
  static const Color lightBackground = Color(0xFFF8F1E7); // crema
  static const Color cardLight = Color(0xFFFFFBF6);
  static const Color warmBorder = Color(0xFFE9D9CB);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [
          Color(0xFFF8F1E7), // cream
          Color(0xFFF3D7D3), // blush
          Color(0xFFE4D8F0), // lavender
          Color(0xFFD8E8EE), // soft sky
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get softCardGradient => const LinearGradient(
        colors: [
          Color(0xFFFFFCF8),
          Color(0xFFF8EFE8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: cardLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF4B3F52),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        color: cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: warmBorder,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: const Color(0xFFFFFAF4),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  selected ? const Color(0xFF735C84) : const Color(0xFF8B7D7A),
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color:
                  selected ? const Color(0xFF735C84) : const Color(0xFF9A8F8A),
              size: 24,
            );
          },
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFCF8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: const Color(0xFF7F736E).withOpacity(0.78),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: warmBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.4,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD7B7C8),
          foregroundColor: const Color(0xFF4B3F52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Color(0xFF4A3F4E),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF584A59),
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF5F5552),
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF726663),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFD6BEDF),
      secondary: const Color(0xFFE8B6AF),
      tertiary: const Color(0xFFB8D3DE),
      surface: const Color(0xFF2E2933),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF1F1B24),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF7EEE5),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF2B2630),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: const Color(0xFF26212B),
        indicatorColor: const Color(0xFFD6BEDF).withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  selected ? const Color(0xFFF1E7DE) : const Color(0xFFB6AEB8),
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color:
                  selected ? const Color(0xFFF1E7DE) : const Color(0xFFB6AEB8),
              size: 24,
            );
          },
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF312B36),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFD6BEDF),
            width: 1.4,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFB998C8),
          foregroundColor: const Color(0xFF241F28),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
