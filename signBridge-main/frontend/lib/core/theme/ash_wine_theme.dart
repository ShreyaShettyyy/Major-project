import 'package:flutter/material.dart';

/// Bespoke "Ash Wine" Color Palette and Dynamic Theme System
///
/// Exact color specifications provided:
/// - CMYK: 0, 18, 6, 80
/// - RGB: 50, 41, 47
/// - HEX: #32292F
class AshWineTheme {
  // Exact Anchor Color (CMYK: 0, 18, 6, 80 | RGB: 50, 41, 47 | #32292F)
  static const Color exactAshWine = Color(0xFF32292F);
  static const Color primary = Color(0xFF32292F);
  static const Color primaryLight = Color(0xFF4C3E47);
  static const Color primaryDark = Color(0xFF1E171C);
  static const Color primaryTint = Color(0xFF6B5A65);

  // ZEN SILK & MORNING MIST (Japandi Light Theme Specification)
  static const Color zenBg = Color(0xFFFAF8F5);             // Warm porcelain white
  static const Color zenCardBg = Color(0xFFFFFFFF);         // Bleached linen white
  static const Color zenCardBorder = Color(0xFFE5E0D8);     // Warm stone hairline border
  static const Color zenCardSecondary = Color(0xFFEDF4F0);  // Pale sage container tint
  static const Color zenSage = Color(0xFF52796F);            // Muted deep sage green
  static const Color zenSageSoft = Color(0xFF84A98C);        // Soft mist sage
  static const Color zenTextDark = Color(0xFF2F3E3B);        // Deep charcoal-sage typography
  static const Color zenTextMuted = Color(0xFF6B7C77);       // Muted sage label text

  // Soft accents & railway highlights
  static const Color mauve = Color(0xFF8F6B7B);
  static const Color rose = Color(0xFFB58D9E);
  static const Color champagne = Color(0xFF52796F); // Zen Sage Accent
  static const Color entityAmber = Color(0xFFD97736); // Proper Noun / Name Highlight
  static const Color alertRed = Color(0xFFC04B54); // Missing child / urgent alert

  // LIGHT THEME CANVASES & SURFACES (Clean, airy, comfortable)
  static const Color bgLight = zenBg; // Warm porcelain white canvas
  static const Color surfaceLight = zenCardBg; // Pure white header / surface
  static const Color cardLight = zenCardBg; // Pure white elevated card
  static const Color cardBorderLight = zenCardBorder; // Subtle warm stone border
  static const Color cardBgSecondaryLight = zenCardSecondary; // Pale sage tint container

  static const Color textPrimaryLight = zenTextDark; // Deep charcoal-sage typography
  static const Color textSecondaryLight = Color(0xFF52605C); // Medium charcoal-sage
  static const Color textMutedLight = zenTextMuted; // Soft muted sage

  // DARK THEME CANVASES & SURFACES (Deep velvet ash wine)
  static const Color bgDark = Color(0xFF1B1518);
  static const Color surfaceDark = Color(0xFF261E23);
  static const Color cardDark = Color(0xFF2E242A);
  static const Color cardBorderDark = Color(0xFF473942);
  static const Color cardBgSecondaryDark = Color(0xFF3B2F36);

  static const Color textPrimaryDark = Color(0xFFFBF8FA);
  static const Color textSecondaryDark = Color(0xFFD4C7CD);
  static const Color textMutedDark = Color(0xFF9E8F96);

  // Dynamic Theme Helpers based on BuildContext
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color bg(BuildContext context) => isDark(context) ? bgDark : bgLight;
  static Color surface(BuildContext context) => isDark(context) ? surfaceDark : surfaceLight;
  static Color card(BuildContext context) => isDark(context) ? cardDark : cardLight;
  static Color cardBorder(BuildContext context) => isDark(context) ? cardBorderDark : cardBorderLight;
  static Color cardBgSecondary(BuildContext context) => isDark(context) ? cardBgSecondaryDark : cardBgSecondaryLight;
  static Color textPrimary(BuildContext context) => isDark(context) ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(BuildContext context) => isDark(context) ? textSecondaryDark : textSecondaryLight;
  static Color textMuted(BuildContext context) => isDark(context) ? textMutedDark : textMutedLight;

  // Gradients
  static const LinearGradient ashWineGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4C3E47),
      Color(0xFF32292F),
      Color(0xFF1E171C),
    ],
  );

  static const LinearGradient wineHeroGradient = ashWineGradient;

  static const LinearGradient ashWineLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8F2F5),
      Color(0xFFEADBDF),
    ],
  );

  static const LinearGradient goldAccentGradient = LinearGradient(
    colors: [
      Color(0xFFE2B788),
      Color(0xFFC7925B),
    ],
  );

  static const LinearGradient properNounGradient = LinearGradient(
    colors: [
      Color(0xFFE88A4C),
      Color(0xFFD97736),
    ],
  );

  // Rich Background Mixture Gradients
  static const LinearGradient bgLightMixtureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAF8F5), // Warm porcelain white
      Color(0xFFF5F2EC), // Soft morning mist
      Color(0xFFEDF4F0), // Pale sage tint
      Color(0xFFFAF8F5), // Light warm highlight
    ],
  );

  static const LinearGradient bgDarkMixtureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B1419), // Deep midnight ash wine
      Color(0xFF261C23), // Rich velvet plum
      Color(0xFF1E161B), // Soft wine ash
      Color(0xFF161014), // Dark grounding base
    ],
  );

  static LinearGradient screenGradient(BuildContext context) =>
      isDark(context) ? bgDarkMixtureGradient : bgLightMixtureGradient;

  static BoxDecoration screenBackgroundDecoration(BuildContext context) =>
      BoxDecoration(gradient: screenGradient(context));

  /// Light Theme (Default: light, clean, human-designed, elegant)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      canvasColor: surfaceLight,
      cardColor: cardLight,
      colorScheme: const ColorScheme.light(
        primary: exactAshWine,
        onPrimary: Colors.white,
        secondary: mauve,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: textPrimaryLight,
        surfaceContainerHighest: cardBgSecondaryLight,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: exactAshWine),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 1,
        shadowColor: const Color(0x1432292F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorderLight, width: 1.2),
        ),
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      canvasColor: surfaceDark,
      cardColor: cardDark,
      colorScheme: const ColorScheme.dark(
        primary: rose,
        onPrimary: Colors.white,
        secondary: mauve,
        onSecondary: Colors.white,
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        surfaceContainerHighest: cardDark,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorderDark, width: 1),
        ),
      ),
    );
  }
}
