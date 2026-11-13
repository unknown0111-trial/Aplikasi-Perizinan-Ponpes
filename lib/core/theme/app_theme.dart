import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const Color seed = Color(0xFF1B5E20);

  static const Color menunggu = Color(0xFFEF6C00);

  static const Color disetujui = Color(0xFF2E7D32);

  static const Color ditolak = Color(0xFFC62828);

  static const Color dibatalkan = Color(0xFF616161);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: seed);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8F6),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
