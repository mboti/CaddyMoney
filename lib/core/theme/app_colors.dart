import 'package:flutter/material.dart';

class AppColors {
  // Fintech Primary - Modern teal/cyan for trust and technology
  static const primary = Color(0xFF00B8A9);
  static const primaryDark = Color(0xFF008C7E);
  static const primaryLight = Color(0xFF4DD4C7);
  
  // Accent - Warm coral for CTAs and important actions
  static const accent = Color(0xFFFF6B6B);
  static const accentDark = Color(0xFFE85555);
  
  // Aliases
  static const secondary = accent;
  static const tertiary = success;
  
  // Success - Green for positive transactions
  static const success = Color(0xFF06D6A0);
  static const successDark = Color(0xFF05B589);
  
  // Warning - Amber for pending states
  static const warning = Color(0xFFFFC107);
  static const warningDark = Color(0xFFF57C00);
  
  // Error - Red for failed transactions
  static const error = Color(0xFFEF476F);
  static const errorDark = Color(0xFFD93A5C);
  
  // Light Mode
  static const lightBackground = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF5F5F5);
  static const lightOnSurface = Color(0xFF1A1A1A);
  static const lightOnSurfaceVariant = Color(0xFF5F6368);
  static const lightBorder = Color(0xFFE0E0E0);
  
  // Dark Mode
  static const darkBackground = Color(0xFF0F1419);
  static const darkSurface = Color(0xFF1A1F26);
  static const darkSurfaceVariant = Color(0xFF252B33);
  static const darkOnSurface = Color(0xFFE8EAED);
  static const darkOnSurfaceVariant = Color(0xFF9AA0A6);
  static const darkBorder = Color(0xFF2A3340);
  
  // Semantic colors
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF5F6368);
  static const textHint = Color(0xFF9AA0A6);
  
  // Transaction type colors
  static const transactionSent = Color(0xFFEF476F);
  static const transactionReceived = Color(0xFF06D6A0);
  static const transactionPending = Color(0xFFFFC107);
}
