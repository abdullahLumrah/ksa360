import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Warm limestone page, paper cards. Text is charcoal, not pure black.
  static const bg = Color(0xFFF4F0E8);
  static const card = Color(0xFFFFFCF7);
  static const chip = Color(0xFFEBE4D8);
  static const line = Color(0xFFE2D9CC);
  static const stroke = Color(0xFFD9CFC0);
  static const mist = Color(0x141C1915);

  static const navy = Color(0xFF1B1916);
  static const ink = Color(0xFF2E2A26);
  static const muted = Color(0xFF6E665C);

  static const green = Color(0xFF1E7A4C);
  static const greenDeep = Color(0xFF143D2C);
  static const gold = Color(0xFF8A5E2E);
  static const goldSoft = Color(0xFF6E4B24);

  /// Cream and bright brass for type that sits on photos, video, or palm green.
  static const onDark = Color(0xFFF7F2E8);
  static const goldBright = Color(0xFFE4C48A);

  static const red = Color(0xFFB33A2B);
  static const redDark = Color(0xFF8E2C22);
}

class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x141C1915),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}

class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.028),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.green,
      onPrimary: AppColors.onDark,
      secondary: AppColors.gold,
      onSecondary: AppColors.onDark,
      // M3 ChoiceChip / FilterChip selected fill + checkmark contrast
      secondaryContainer: AppColors.greenDeep,
      onSecondaryContainer: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.navy,
      error: AppColors.red,
      onError: Colors.white,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.navy,
    );

    final radius = BorderRadius.circular(18);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      textTheme: textTheme,
      splashColor: AppColors.gold.withValues(alpha: 0.22),
      highlightColor: AppColors.gold.withValues(alpha: 0.1),
      splashFactory: InkSparkle.splashFactory,
      dividerColor: AppColors.line,
      iconTheme: const IconThemeData(color: AppColors.gold),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.gold),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.stroke),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chip,
        selectedColor: AppColors.greenDeep,
        checkmarkColor: Colors.white,
        deleteIconColor: Colors.white,
        side: const BorderSide(color: AppColors.stroke),
        labelStyle: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.greenDeep;
          }
          return AppColors.chip;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.gold,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: AppColors.navy),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.gold,
        textColor: AppColors.navy,
        subtitleTextStyle: TextStyle(color: AppColors.muted, height: 1.35),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.gold,
        collapsedIconColor: AppColors.muted,
        textColor: AppColors.navy,
        collapsedTextColor: AppColors.navy,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.greenDeep,
        contentTextStyle: const TextStyle(
          color: AppColors.onDark,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SoftPageTransitionsBuilder(),
          TargetPlatform.iOS: SoftPageTransitionsBuilder(),
        },
      ),
    );
  }
}
