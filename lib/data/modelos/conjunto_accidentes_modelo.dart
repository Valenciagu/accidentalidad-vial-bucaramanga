import 'dart:typed_data';

import '../../domain/entidades/conjunto_accidentes.dart';

/// Traduce el JSON generado por el ETL a las entidades del dominio.
class ConjuntoAccidentesModelo {
  static ConjuntoAccidentes desdeJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    final columnas = json['columnas'] as Map<String, dynamic>;

    List<int> columna(String nombre) => (columnas[nombre] as List).cast<int>();

    return ConjuntoAccidentes(
      fechas: Int32List.fromList(columna('fecha')),
      dias: Uint8List.fromList(columna('dia')),
      horas: Uint8List.fromList(columna('hora')),
      gravedades: Uint8List.fromList(columna('gravedad')),
      barrios: Uint16List.fromList(columna('barrio')),
      mascaras: Uint16List.fromList(columna('mascara')),
      vehiculos: Uint8List.fromList(columna('vehiculos')),
      empresas: Uint8List.fromList(columna('empresa')),
      policias: Uint8List.fromList(columna('policia')),
      catalogoComunas: [
        for (final comuna in json['comunas'] as List)
          Comuna(
            numero: comuna['numero'] as int,
            nombre: comuna['nombre'] as String,
            lat: (comuna['lat'] as num?)?.toDouble(),
            lon: (comuna['lon'] as num?)?.toDouble(),
          ),
      ],
      catalogoBarrios: [
        for (final barrio in json['barrios'] as List)
          Barrio(
            nombre: barrio['nombre'] as String,
            comuna: barrio['comuna'] as int,
            lat: (barrio['lat'] as num?)?.toDouble(),
            lon: (barrio['lon'] as num?)?.toDouble(),
            aproximado: barrio['aprox'] as bool,
          ),
      ],
      reporte: ReporteCalidad(
        fuente: meta['fuente'] as String,
        fechaMinima: meta['fecha_min'] as int,
        fechaMaxima: meta['fecha_max'] as int,
        valores: (meta['reporte'] as Map<String, dynamic>).cast<String, int>(),
      ),
    );
  }
}
