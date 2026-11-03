import 'dart:typed_data';

/// Comuna o corregimiento. Los corregimientos tienen [numero] 0.
class Comuna {
  const Comuna({
    required this.numero,
    required this.nombre,
    this.lat,
    this.lon,
  });

  final int numero;
  final String nombre;
  final double? lat;
  final double? lon;

  bool get urbana => numero > 0;
  bool get tieneUbicacion => lat != null && lon != null;
  String get etiqueta => urbana ? 'Comuna $numero · $nombre' : nombre;
}

class Barrio {
  const Barrio({
    required this.nombre,
    required this.comuna,
    this.lat,
    this.lon,
    this.aproximado = false,
  });

  final String nombre;
  final int comuna;
  final double? lat;
  final double? lon;

  /// La coordenada es el centro de la comuna, no la del barrio.
  final bool aproximado;

  bool get tieneUbicacion => lat != null && lon != null;
}

/// Resultado de la depuración hecha por el ETL (RF-02).
class ReporteCalidad {
  const ReporteCalidad({
    required this.fuente,
    required this.fechaMinima,
    required this.fechaMaxima,
    required this.valores,
  });

  final String fuente;
  final int fechaMinima;
  final int fechaMaxima;
  final Map<String, int> valores;

  int valor(String clave) => valores[clave] ?? 0;
}

/// Tabla de accidentes en formato columnar, ordenada por fecha.
///
/// Guardar cada columna en un arreglo tipado permite recorrer los registros
/// con acceso O(1) por posición y es la base de la búsqueda binaria por año.
class ConjuntoAccidentes {
  ConjuntoAccidentes({
    required this.fechas,
    required this.dias,
    required this.horas,
    required this.gravedades,
    required this.barrios,
    required this.mascaras,
    required this.vehiculos,
    required this.empresas,
    required this.policias,
    required this.catalogoComunas,
    required this.catalogoBarrios,
    required this.reporte,
  }) : anioMinimo = fechas.first ~/ 10000,
       anioMaximo = fechas.last ~/ 10000;

  final Int32List fechas;
  final Uint8List dias;
  final Uint8List horas;
  final Uint8List gravedades;
  final Uint16List barrios;
  final Uint16List mascaras;
  final Uint8List vehiculos;
  final Uint8List empresas;
  final Uint8List policias;
  final List<Comuna> catalogoComunas;
  final List<Barrio> catalogoBarrios;
  final ReporteCalidad reporte;
  final int anioMinimo;
  final int anioMaximo;

  int get n => fechas.length;
  int get cantidadAnios => anioMaximo - anioMinimo + 1;
  int get ultimoMes => fechas.last ~/ 100 % 100;

  /// Último mes con datos de un año: los años completos llegan a diciembre.
  int ultimoMesDe(int anio) => anio == anioMaximo ? ultimoMes : 12;
}
