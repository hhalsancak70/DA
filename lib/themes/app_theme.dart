import 'package:flutter/material.dart';

class AppTheme {
  // Ana renkler
  static const Color primaryColor = Color(0xFFE53935);
  static const Color secondaryColor = Color(0xFFF44336);
  static const Color accentColor = Color(0xFFEF5350);
  
  // Nötr renkler
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color cardColor = Colors.white;
  static const Color shadowColor = Color(0x1A000000);
  
  // Metin renkleri
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Durum renkleri
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFD32F2F);
  
  // Gradyan renkler
  static const List<Color> primaryGradient = [
    Color(0xFFE53935),
    Color(0xFFFF5252),
  ];
  
  // Buton stilleri
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primaryColor,
    elevation: 1,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: primaryColor, width: 1),
    ),
  );
  
  // Input dekorasyonları
  static InputDecoration inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: textSecondary),
      prefixIcon: Icon(prefixIcon, color: primaryColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
  
  // Kart dekorasyonu
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Arka plan gradyanı
  static BoxDecoration backgroundGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
    ),
  );
  
  // AppBar teması
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: primaryColor,
    centerTitle: false,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
} 