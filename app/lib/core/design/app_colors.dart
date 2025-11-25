import 'package:flutter/material.dart';

/// Cores do Design System Symplus Finance
/// Baseado na identidade SymplusTech (verde-neon + preto)
class AppColors {
  AppColors._();

  // Primary - Verde Neon SymplusTech (reduzida saturação para melhor contraste)
  static const Color primary = Color(0xFFB8E62A); // Verde neon com saturação reduzida
  static const Color primaryDark = Color(0xFF9BC922); // Verde mais escuro para hover/pressed
  static const Color primaryLight = Color(0xFFD4F05A); // Verde mais claro para backgrounds

  // Secondary - Roxo/Profundo
  static const Color secondary = Color(0xFF6B46C1); // Roxo profundo
  static const Color secondaryDark = Color(0xFF553C9A);
  static const Color secondaryLight = Color(0xFF8B6FD4);

  // Backgrounds
  static const Color background = Color(0xFFFAFAFA); // Cinza muito claro (quase branco)
  static const Color backgroundLight = Color(0xFFF5F5F5); // Very light gray for web background
  static const Color scaffoldBackground = Color(0xFFF5F5F5); // Levemente diferente para profundidade
  static const Color surface = Colors.white; // Branco para cards e painéis
  static const Color surfaceLight = Colors.white; // White for cards and panels

  // Text - Melhor contraste
  static const Color onBackground = Color(0xFF1A1A1A); // Preto suave para melhor contraste
  static const Color onBackgroundDark = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF2D2D2D); // Cinza escuro para melhor legibilidade
  static const Color onSurfaceDark = Color(0xFF2D2D2D);
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF555555); // Cinza médio com melhor contraste
  static const Color textTertiary = Color(0xFF888888); // Cinza claro mas legível

  // Estados
  static const Color success = Color(0xFF10B981); // Verde sóbrio (não neon)
  static const Color error = Color(0xFFEF4444); // Vermelho
  static const Color warning = Color(0xFFF59E0B); // Laranja/âmbar
  static const Color info = Color(0xFF3B82F6); // Azul

  // Financeiro
  static const Color income = Color(0xFF10B981); // Verde para receitas
  static const Color expense = Color(0xFFEF4444); // Vermelho para despesas

  // Paleta de gráficos (5-7 cores harmônicas)
  static const List<Color> chartColors = [
    Color(0xFF6B46C1), // Roxo
    Color(0xFF3B82F6), // Azul
    Color(0xFF10B981), // Verde
    Color(0xFFF59E0B), // Laranja
    Color(0xFFEC4899), // Rosa
    Color(0xFF8B5CF6), // Roxo claro
    Color(0xFF06B6D4), // Ciano
  ];

  // Bordas e divisores
  static const Color border = Color(0xFFE5E7EB); // Cinza claro para bordas
  static const Color divider = Color(0xFFE5E7EB); // Cinza claro para divisores

  // Overlay e backdrop
  static const Color overlay = Color(0x80000000); // Preto semi-transparente
  static const Color backdrop = Color(0x40000000); // Preto mais transparente
}

