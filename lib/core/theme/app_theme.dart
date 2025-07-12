import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/hex_color.dart';

class AppTheme {
  // Colors
  static final Color primaryColor = HexColor('#00967B');
  static final Color accentColor = HexColor('#FFB72B');
  static final Color backgroundColor = Colors.white;
  static final Color white = HexColor("#ffffff");
  static final Color surfaceColor = HexColor('#F7F7F7');
  static final Color errorColor = HexColor('#D32F2F');
  static final Color successColor = HexColor('#388E3C');
  static final Color warningColor = HexColor('#FFA000');
  static final Color infoColor = HexColor('#1976D2');

  // Text colors
  static final Color textPrimaryColor = HexColor('#212121');
  static final Color textSecondaryColor = HexColor('#757575');
  static final Color textTertiaryColor = HexColor('#9E9E9E');

  // Status colors
  static final Color pendingColor = HexColor('#FFA000');
  static final Color confirmedColor = HexColor('#1976D2');
  static final Color inProgressColor = HexColor('#00967B');
  static final Color completedColor = HexColor('#388E3C');
  static final Color cancelledColor = HexColor('#D32F2F');

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: HexColor('#E0E0E0')),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: HexColor('#E0E0E0')),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      hintStyle: TextStyle(color: textTertiaryColor),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondaryColor,
      indicatorColor: primaryColor,
    ),
    dividerTheme: DividerThemeData(
      color: HexColor('#EEEEEE'),
      thickness: 1,
      space: 1,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: textPrimaryColor),
      bodyMedium: TextStyle(color: textSecondaryColor),
      bodySmall: TextStyle(color: textTertiaryColor),
      labelLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: primaryColor),
      labelSmall: TextStyle(color: primaryColor),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: HexColor('#323232'),
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor),
    chipTheme: ChipThemeData(
      backgroundColor: HexColor('#F5F5F5'),
      disabledColor: HexColor('#E0E0E0'),
      selectedColor: primaryColor.withOpacity(0.1),
      secondarySelectedColor: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(color: textPrimaryColor),
      secondaryLabelStyle: TextStyle(color: primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
    ),
  );

  // Dark theme - we could implement this later if needed
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    // Dark theme configuration would go here
  );
}
