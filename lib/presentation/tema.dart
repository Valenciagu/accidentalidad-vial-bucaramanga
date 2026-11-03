import 'package:flutter/material.dart';

/// Colores tomados de los mockups del informe.
class Colores {
  static const Color encabezado = Color(0xFF1B4F86);
  static const Color primario = Color(0xFF0B6FE0);
  static const Color primarioSuave = Color(0xFFE6F0FC);
  static const Color fondo = Color(0xFFF5F7FA);
  static const Color superficie = Colors.white;
  static const Color borde = Color(0xFFE1E6ED);
  static const Color texto = Color(0xFF16263A);
  static const Color textoSuave = Color(0xFF5B6B7E);
  static const Color exito = Color(0xFF1E8E4E);
  static const Color peligro = Color(0xFFD32F2F);
  static const Color alerta = Color(0xFFE08A00);

  static const List<Color> densidad = [
    Color(0xFF4C8DF0), // Muy baja
    Color(0xFF46C281), // Baja
    Color(0xFFF2C230), // Media
    Color(0xFFF28C28), // Alta
    Color(0xFFE02B2B), // Muy alta
  ];
}

ThemeData crearTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Colores.primario,
    primary: Colores.primario,
    surface: Colores.superficie,
  );
  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: Colores.borde),
  );

  return ThemeData(
    colorScheme: esquema,
    scaffoldBackgroundColor: Colores.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.encabezado,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colores.superficie,
      indicatorColor: Colores.primarioSuave,
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith((estados) {
        final activo = estados.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          color: activo ? Colores.primario : Colores.textoSuave,
          fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colores.superficie,
      border: bordeCampo,
      enabledBorder: bordeCampo,
    ),
  );
}
