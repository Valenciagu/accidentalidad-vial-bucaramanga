import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entidades/conjunto_accidentes.dart';
import '../../domain/repositorios/repositorio_accidentes.dart';
import '../generadores/generador_sintetico.dart';
import '../modelos/conjunto_accidentes_modelo.dart';

/// Lee el dataset depurado que viaja dentro de la app, así funciona sin conexión,
/// y lo completa con accidentes sintéticos hasta la cantidad pedida.
class RepositorioAccidentesAsset implements RepositorioAccidentes {
  const RepositorioAccidentesAsset();

  static const String _ruta = 'assets/datos/accidentes.json';

  @override
  int get disponibles => GeneradorSintetico.totalDisponible;

  @override
  Future<ConjuntoAccidentes> cargar(int cantidad) async {
    final texto = await rootBundle.loadString(_ruta);
    // Decodificar y generar un millón de registros bloquearía la interfaz.
    return compute(_construir, (texto, cantidad));
  }
}

ConjuntoAccidentes _construir((String, int) entrada) {
  final (texto, cantidad) = entrada;
  final reales = ConjuntoAccidentesModelo.desdeJson(
    jsonDecode(texto) as Map<String, dynamic>,
  );
  return GeneradorSintetico.tomar(reales, cantidad);
}
