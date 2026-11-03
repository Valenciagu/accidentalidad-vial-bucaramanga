import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entidades/conjunto_accidentes.dart';
import '../../domain/repositorios/repositorio_accidentes.dart';
import '../modelos/conjunto_accidentes_modelo.dart';

/// Lee el dataset depurado que viaja dentro de la app, así funciona sin conexión.
class RepositorioAccidentesAsset implements RepositorioAccidentes {
  const RepositorioAccidentesAsset();

  static const String _ruta = 'assets/datos/accidentes.json';

  @override
  Future<ConjuntoAccidentes> cargar() async {
    final texto = await rootBundle.loadString(_ruta);
    final json = jsonDecode(texto) as Map<String, dynamic>;
    return ConjuntoAccidentesModelo.desdeJson(json);
  }
}
