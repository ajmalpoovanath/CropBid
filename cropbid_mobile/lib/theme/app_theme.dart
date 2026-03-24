import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color paddyGreen = Color(0xFF52B788); 
  static const Color clayRed = Color(0xFFD98A8F); 
  static const Color backgroundForest = Color(0xFF0B251A); 
  static const Color surfaceMoss = Color(0xFF153A2A); 

  // Aliases for compatibility
  static const Color primaryGreen = paddyGreen; 
  static const Color secondaryClay = clayRed;
  static const Color backgroundCream = backgroundForest; 

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundForest,
      colorScheme: const ColorScheme.dark(
        primary: paddyGreen,
        secondary: clayRed,
        surface: surfaceMoss,
        onSurface: Colors.white, // 👈 Ensures text on cards is white
        onBackground: Colors.white, // 👈 Ensures general text is white
      ),
      
      // 📖 FIX: Global Text Readability
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white, 
        displayColor: Colors.white,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceMoss,
        indicatorColor: paddyGreen.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, 
        height: 70,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: paddyGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceMoss,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.1)), 
        ),
      ),

      // 🎹 FIX: Input Field (TextField) Readability
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMoss.withOpacity(0.5),
        hintStyle: const TextStyle(color: Colors.white60), // 👈 Makes "Username/Password" readable
        prefixIconColor: paddyGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        // Ensure typed text is bright white
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}