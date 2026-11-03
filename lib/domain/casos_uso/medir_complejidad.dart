import 'dart:math' as math;

import '../algoritmos/busqueda_binaria.dart';
import '../algoritmos/cobertura_maxima.dart';
import '../algoritmos/merge_sort.dart';
import '../entidades/conjunto_accidentes.dart';
import '../entidades/filtros.dart';
import '../entidades/resumen.dart';
import 'consultar_accidentes.dart';
import 'planificar_operativos.dart';

class MedicionTamano {
  const MedicionTamano({
    required this.n,
    required this.busquedaUs,
    required this.filtradoUs,
    required this.ordenamientoUs,
  });

  final int n;
  final double busquedaUs;
  final double filtradoUs;
  final double ordenamientoUs;
}

class MedicionPlan {
  const MedicionPlan({
    required this.k,
    required this.espacio,
    required this.nodos,
    required this.exactoUs,
    required this.vorazUs,
    required this.optimoDemostrado,
    required this.calidadVoraz,
  });

  final int k;
  final double espacio;
  final int nodos;
  final int exactoUs;
  final int vorazUs;
  final bool optimoDemostrado;
  final double calidadVoraz;
}

class ReporteComplejidad {
  const ReporteComplejidad({required this.tamanos, required this.planes});

  final List<MedicionTamano> tamanos;
  final List<MedicionPlan> planes;
}

/// Mide tiempos reales sobre el dispositivo, igual que `example_04.py` en clase.
class MedirComplejidad {
  const MedirComplejidad(this._consultar, this._planificar);

  final ConsultarAccidentes _consultar;
  final PlanificarOperativos _planificar;

  static const int _repeticiones = 7;

  ReporteComplejidad call(ConjuntoAccidentes datos, Resumen general) {
    // La primera pasada corre sin optimizar y falsearía el tamaño más pequeño.
    _medirTamano(datos, datos.n);

    final tamanos = <MedicionTamano>[];
    for (final divisor in const [8, 4, 2, 1]) {
      tamanos.add(_medirTamano(datos, datos.n ~/ divisor));
    }

    final planes = <MedicionPlan>[];
    for (var k = 1; k <= 6; k++) {
      final parametros = ParametrosPlan(
        k: k,
        alcanceKm: 1.5,
        duracionHoras: 4,
        limiteMicrosegundos: 3000000,
      );
      final (instancia, _) = _planificar.construirInstancia(datos, general, parametros);
      final voraz = resolverVoraz(instancia);
      final exacto = resolverExacto(instancia, limiteMicrosegundos: 3000000);
      planes.add(MedicionPlan(
        k: k,
        espacio: combinaciones(instancia.m, k),
        nodos: exacto.nodos,
        exactoUs: exacto.microsegundos,
        vorazUs: voraz.microsegundos,
        optimoDemostrado: exacto.optimoDemostrado,
        calidadVoraz: exacto.valor == 0 ? 1 : voraz.valor / exacto.valor,
      ));
    }
    return ReporteComplejidad(tamanos: tamanos, planes: planes);
  }

  MedicionTamano _medirTamano(ConjuntoAccidentes datos, int n) {
    final prefijo = datos.fechas.sublist(0, n);
    final azar = math.Random(7);
    final desordenados = List<int>.generate(n, (_) => azar.nextInt(1 << 30));

    return MedicionTamano(
      n: n,
      busquedaUs: _mediana(() {
        for (var i = 0; i < 1000; i++) {
          limiteInferior(prefijo, prefijo[(i * 97) % n]);
        }
      }) / 1000,
      filtradoUs: _mediana(() {
        _consultar.recorridoCompleto(
          datos,
          const Filtros(mes: 7),
          hasta: n,
        );
      }),
      ordenamientoUs: _mediana(() {
        mergeSort<int>(desordenados, (a, b) => a.compareTo(b));
      }),
    );
  }

  double _mediana(void Function() accion) {
    final tiempos = <int>[];
    final reloj = Stopwatch()..start();
    for (var i = 0; i < _repeticiones; i++) {
      final inicio = reloj.elapsedMicroseconds;
      accion();
      tiempos.add(reloj.elapsedMicroseconds - inicio);
    }
    tiempos.sort();
    return tiempos[_repeticiones ~/ 2].toDouble();
  }
}
