import 'dart:async';

import 'package:http/http.dart' as http;

import '../../domain/entidades/estado_servicio.dart';
import '../../domain/repositorios/repositorio_conectividad.dart';

/// Comprueba los servicios externos con una petición real a cada uno.
class RepositorioConectividadHttp implements RepositorioConectividad {
  const RepositorioConectividadHttp();

  static const Duration _espera = Duration(seconds: 6);

  @override
  Future<List<EstadoServicio>> verificar() {
    return Future.wait([
      _probar(
        'Datos Abiertos Colombia',
        'Fuente oficial del dataset',
        'https://www.datos.gov.co/resource/7cci-nqqb.json?\$limit=1',
      ),
      _probar(
        'Mapas OpenStreetMap',
        'Cartografía del análisis geográfico',
        'https://tile.openstreetmap.org/12/1203/1947.png',
      ),
    ]);
  }

  Future<EstadoServicio> _probar(String nombre, String descripcion, String url) async {
    final reloj = Stopwatch()..start();
    try {
      final respuesta = await http.get(Uri.parse(url)).timeout(_espera);
      return EstadoServicio(
        nombre: nombre,
        descripcion: descripcion,
        disponible: respuesta.statusCode == 200,
        latenciaMs: reloj.elapsedMilliseconds,
      );
    } on Exception {
      return EstadoServicio(nombre: nombre, descripcion: descripcion, disponible: false);
    }
  }
}
