import 'package:flutter/material.dart';

/// Sombras do Design System Symplus Finance
/// Sombras suaves, próximas aos exemplos, nada pesado
class AppShadows {
  AppShadows._();

  // Card shadow (suave)
  static const BoxShadow card = BoxShadow(
    color: Color(0x0A000000), // Preto 4% opacidade
    blurRadius: 8,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  // Elevated card shadow (um pouco mais pronunciada)
  static const BoxShadow cardElevated = BoxShadow(
    color: Color(0x0F000000), // Preto 6% opacidade
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  // Button shadow
  static const BoxShadow button = BoxShadow(
    color: Color(0x14000000), // Preto 8% opacidade
    blurRadius: 8,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  // FAB shadow
  static const BoxShadow fab = BoxShadow(
    color: Color(0x1A000000), // Preto 10% opacidade
    blurRadius: 16,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );
}

