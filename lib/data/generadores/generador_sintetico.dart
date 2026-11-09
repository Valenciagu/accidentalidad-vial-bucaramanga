import 'dart:math' as math;
import 'dart:typed_data';

import '../../domain/entidades/conjunto_accidentes.dart';

/// Arma un conjunto de exactamente `cantidad` accidentes a partir de los reales.
///
/// Se comporta como una lista fija de [totalDisponible] elementos de la que se
/// toman los primeros `cantidad`:
///
/// 1. Primero van los reales. Si se piden menos que los reales, se toma una
///    muestra aleatoria de ellos.
/// 2. Después van los sintéticos. El sintético j se genera siempre igual por
///    la semilla fija, así que pedir 300.000 incluye los mismos sintéticos que
///    pedir 102.356, más otros.
///
/// Cada sintético copia los atributos de un accidente real elegido al azar
/// (hora, barrio, gravedad, vehículos, empresa, policía) y recibe una fecha
/// nueva del mismo año, mes y día de la semana. Así conserva las distribuciones
/// y las correlaciones de los datos reales, sin repetir fechas exactas.
///
/// Complejidad: O(n + d), con d los días del calendario, porque el orden por
/// fecha se hace con conteo y no con comparaciones.
class GeneradorSintetico {
  const GeneradorSintetico._();

  static const int totalDisponible = 1100000;
  static const int semilla = 2026;

  static ConjuntoAccidentes tomar(ConjuntoAccidentes reales, int cantidad) {
    if (cantidad < 1 || cantidad > totalDisponible) {
      throw RangeError.range(cantidad, 1, totalDisponible, 'cantidad');
    }
    if (reales.n > totalDisponible) {
      throw StateError('Hay más registros reales que el total disponible');
    }
    if (cantidad == reales.n) return reales;
    if (cantidad < reales.n) return _muestraReal(reales, cantidad);
    return _conSinteticos(reales, cantidad - reales.n);
  }

  /// Muestra aleatoria sin reemplazo (Fisher-Yates parcial), en orden de fecha.
  static ConjuntoAccidentes _muestraReal(ConjuntoAccidentes reales, int cantidad) {
    final azar = math.Random(semilla);
    final indices = Int32List.fromList(List<int>.generate(reales.n, (i) => i));
    for (var i = 0; i < cantidad; i++) {
      final j = i + azar.nextInt(reales.n - i);
      final temporal = indices[i];
      indices[i] = indices[j];
      indices[j] = temporal;
    }
    // Los reales ya están ordenados por fecha: ordenar las posiciones basta.
    final elegidos = Int32List.sublistView(indices, 0, cantidad)..sort();

    final tabla = _Tabla(cantidad);
    for (var i = 0; i < cantidad; i++) {
      tabla.copiar(i, reales, elegidos[i]);
    }
    return tabla.armar(reales, sinteticos: 0);
  }

  static ConjuntoAccidentes _conSinteticos(ConjuntoAccidentes reales, int cantidad) {
    final calendario = _Calendario(reales);
    final sinteticos = _Tabla(cantidad);
    final azar = math.Random(semilla);

    for (var j = 0; j < cantidad; j++) {
      final plantilla = azar.nextInt(reales.n);
      sinteticos.copiar(j, reales, plantilla);
      sinteticos.fechas[j] = calendario.fechaParecida(
        reales.fechas[plantilla],
        reales.dias[plantilla],
        azar,
      );
    }
    return _ordenarPorFecha(reales, sinteticos, calendario);
  }

  /// Counting sort estable por día: los reales quedan antes que los sintéticos
  /// del mismo día y cada grupo conserva su orden.
  static ConjuntoAccidentes _ordenarPorFecha(
    ConjuntoAccidentes reales,
    _Tabla sinteticos,
    _Calendario calendario,
  ) {
    final total = reales.n + sinteticos.n;
    final posiciones = Int32List(calendario.cantidadDias + 1);
    for (var i = 0; i < reales.n; i++) {
      posiciones[calendario.clave(reales.fechas[i]) + 1]++;
    }
    for (var i = 0; i < sinteticos.n; i++) {
      posiciones[calendario.clave(sinteticos.fechas[i]) + 1]++;
    }
    for (var d = 1; d < posiciones.length; d++) {
      posiciones[d] += posiciones[d - 1];
    }

    final salida = _Tabla(total);
    for (var i = 0; i < reales.n; i++) {
      salida.copiar(posiciones[calendario.clave(reales.fechas[i])]++, reales, i);
    }
    for (var i = 0; i < sinteticos.n; i++) {
      final destino = posiciones[calendario.clave(sinteticos.fechas[i])]++;
      salida.copiarDeTabla(destino, sinteticos, i);
    }
    return salida.armar(reales, sinteticos: sinteticos.n);
  }
}

/// Días por mes y día de la semana del primer día, para los años del dataset.
class _Calendario {
  _Calendario(ConjuntoAccidentes reales)
      : _anioBase = reales.anioMinimo,
        _fechaMaxima = reales.fechas.last,
        cantidadDias = reales.cantidadAnios * 12 * 31,
        _primerDia = Uint8List(reales.cantidadAnios * 12),
        _diasDelMes = Uint8List(reales.cantidadAnios * 12) {
    for (var a = 0; a < reales.cantidadAnios; a++) {
      for (var m = 0; m < 12; m++) {
        final anio = _anioBase + a;
        _primerDia[a * 12 + m] = DateTime.utc(anio, m + 1, 1).weekday;
        _diasDelMes[a * 12 + m] = DateTime.utc(anio, m + 2, 0).day;
      }
    }
  }

  final int _anioBase;
  final int _fechaMaxima;
  final int cantidadDias;
  final Uint8List _primerDia;
  final Uint8List _diasDelMes;

  /// Posición de la fecha en una rejilla de 31 días por mes.
  int clave(int fecha) {
    final anio = fecha ~/ 10000;
    final mes = fecha ~/ 100 % 100;
    return ((anio - _anioBase) * 12 + mes - 1) * 31 + fecha % 100 - 1;
  }

  /// Fecha al azar del mismo año y mes que [fecha] que cae en [diaSemana]
  /// (1 = lunes) y no pasa de la última fecha real.
  int fechaParecida(int fecha, int diaSemana, math.Random azar) {
    final anio = fecha ~/ 10000;
    final mes = fecha ~/ 100 % 100;
    final indice = (anio - _anioBase) * 12 + mes - 1;
    var ultimo = _diasDelMes[indice];
    if (fecha ~/ 100 == _fechaMaxima ~/ 100) ultimo = _fechaMaxima % 100;

    final primero = 1 + (diaSemana - _primerDia[indice] + 7) % 7;
    if (primero > ultimo) return fecha;
    final opciones = (ultimo - primero) ~/ 7 + 1;
    return anio * 10000 + mes * 100 + primero + 7 * azar.nextInt(opciones);
  }
}

/// Columnas tipadas en construcción.
class _Tabla {
  _Tabla(this.n)
      : fechas = Int32List(n),
        dias = Uint8List(n),
        horas = Uint8List(n),
        gravedades = Uint8List(n),
        barrios = Uint16List(n),
        mascaras = Uint16List(n),
        vehiculos = Uint8List(n),
        empresas = Uint8List(n),
        policias = Uint8List(n);

  final int n;
  final Int32List fechas;
  final Uint8List dias;
  final Uint8List horas;
  final Uint8List gravedades;
  final Uint16List barrios;
  final Uint16List mascaras;
  final Uint8List vehiculos;
  final Uint8List empresas;
  final Uint8List policias;

  void copiar(int destino, ConjuntoAccidentes origen, int i) {
    fechas[destino] = origen.fechas[i];
    dias[destino] = origen.dias[i];
    horas[destino] = origen.horas[i];
    gravedades[destino] = origen.gravedades[i];
    barrios[destino] = origen.barrios[i];
    mascaras[destino] = origen.mascaras[i];
    vehiculos[destino] = origen.vehiculos[i];
    empresas[destino] = origen.empresas[i];
    policias[destino] = origen.policias[i];
  }

  void copiarDeTabla(int destino, _Tabla origen, int i) {
    fechas[destino] = origen.fechas[i];
    dias[destino] = origen.dias[i];
    horas[destino] = origen.horas[i];
    gravedades[destino] = origen.gravedades[i];
    barrios[destino] = origen.barrios[i];
    mascaras[destino] = origen.mascaras[i];
    vehiculos[destino] = origen.vehiculos[i];
    empresas[destino] = origen.empresas[i];
    policias[destino] = origen.policias[i];
  }

  ConjuntoAccidentes armar(ConjuntoAccidentes reales, {required int sinteticos}) {
    return ConjuntoAccidentes(
      fechas: fechas,
      dias: dias,
      horas: horas,
      gravedades: gravedades,
      barrios: barrios,
      mascaras: mascaras,
      vehiculos: vehiculos,
      empresas: empresas,
      policias: policias,
      catalogoComunas: reales.catalogoComunas,
      catalogoBarrios: reales.catalogoBarrios,
      reporte: reales.reporte,
      sinteticos: sinteticos,
    );
  }
}
