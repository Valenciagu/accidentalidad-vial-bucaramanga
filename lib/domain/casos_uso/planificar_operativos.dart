import 'dart:math' as math;

import '../algoritmos/cobertura_maxima.dart';
import '../entidades/conjunto_accidentes.dart';
import '../entidades/resumen.dart';

/// Operativo candidato: punto base en una comuna un día de la semana.
class Operativo {
  const Operativo({
    required this.comuna,
    required this.comunasCubiertas,
    required this.dia,
    required this.horaInicio,
    required this.duracion,
  });

  final int comuna;
  final List<int> comunasCubiertas;

  /// De 0 (lunes) a 6 (domingo).
  final int dia;
  final int horaInicio;
  final int duracion;

  int get horaFin => (horaInicio + duracion) % 24;
}

class PlanOperativos {
  const PlanOperativos({
    required this.operativos,
    required this.voraz,
    required this.exacto,
    required this.pesoTotal,
    required this.candidatos,
    required this.espacioBusqueda,
  });

  /// Operativos de la mejor solución.
  final List<Operativo> operativos;
  final SolucionCobertura voraz;
  final SolucionCobertura exacto;
  final int pesoTotal;
  final int candidatos;
  final double espacioBusqueda;

  double get porcentajeCubierto =>
      pesoTotal == 0 ? 0 : exacto.valor * 100 / pesoTotal;

  /// Calidad de la solución voraz frente al óptimo, entre 0 y 1.
  double get calidadVoraz => exacto.valor == 0 ? 1 : voraz.valor / exacto.valor;
}

/// Parámetros simples del plan. Se pueden enviar a otro hilo.
class ParametrosPlan {
  const ParametrosPlan({
    required this.k,
    required this.alcanceKm,
    required this.duracionHoras,
    required this.limiteMicrosegundos,
  });

  final int k;
  final double alcanceKm;
  final int duracionHoras;
  final int limiteMicrosegundos;
}

/// Elige dónde y cuándo ubicar k operativos para cubrir más accidentes.
///
/// Se modela como Cobertura Máxima: cada celda (comuna, día, hora) es un
/// elemento del universo con peso igual a sus accidentes, y cada operativo
/// cubre las celdas de las comunas a su alcance durante su turno. Los turnos
/// y las zonas se solapan, y por eso elegir el mejor conjunto es difícil.
/// Cada comuna recibe como máximo un operativo: sin esta regla todos caerían
/// en la misma zona central, lo que no sirve como recomendación.
class PlanificarOperativos {
  const PlanificarOperativos();

  static const int separacionFranjas = 2;

  (InstanciaCobertura, List<Operativo>) construirInstancia(
    ConjuntoAccidentes datos,
    Resumen resumen,
    ParametrosPlan parametros,
  ) {
    final comunas = datos.catalogoComunas;
    final operativos = <Operativo>[];
    final conjuntos = <List<int>>[];
    final grupos = <int>[];

    for (var base = 0; base < comunas.length; base++) {
      if (!comunas[base].urbana || !comunas[base].tieneUbicacion) continue;
      final cubiertas = <int>[
        for (var otra = 0; otra < comunas.length; otra++)
          if (comunas[otra].urbana &&
              comunas[otra].tieneUbicacion &&
              distanciaKm(comunas[base], comunas[otra]) <= parametros.alcanceKm)
            otra,
      ];
      for (var dia = 0; dia < 7; dia++) {
        for (var inicio = 0; inicio < 24; inicio += separacionFranjas) {
          operativos.add(Operativo(
            comuna: base,
            comunasCubiertas: cubiertas,
            dia: dia,
            horaInicio: inicio,
            duracion: parametros.duracionHoras,
          ));
          grupos.add(base);
          conjuntos.add([
            for (final comuna in cubiertas)
              for (var h = 0; h < parametros.duracionHoras; h++)
                comuna * horasPorSemana + (dia * 24 + inicio + h) % horasPorSemana,
          ]);
        }
      }
    }

    return (
      InstanciaCobertura(
        pesos: resumen.porComunaDiaHora,
        conjuntos: conjuntos,
        k: parametros.k,
        grupos: grupos,
      ),
      operativos,
    );
  }

  PlanOperativos call(
    ConjuntoAccidentes datos,
    Resumen resumen,
    ParametrosPlan parametros,
  ) {
    final (instancia, operativos) = construirInstancia(datos, resumen, parametros);
    final voraz = resolverVoraz(instancia);
    final exacto = resolverExacto(
      instancia,
      limiteMicrosegundos: parametros.limiteMicrosegundos,
    );

    return PlanOperativos(
      operativos: [for (final indice in exacto.elegidos) operativos[indice]],
      voraz: voraz,
      exacto: exacto,
      pesoTotal: resumen.total,
      candidatos: instancia.m,
      espacioBusqueda: combinaciones(instancia.m, parametros.k),
    );
  }

  /// Distancia entre centros de comuna con la fórmula de Haversine.
  double distanciaKm(Comuna a, Comuna b) {
    const radioTierra = 6371.0;
    final latA = a.lat! * math.pi / 180;
    final latB = b.lat! * math.pi / 180;
    final deltaLat = latB - latA;
    final deltaLon = (b.lon! - a.lon!) * math.pi / 180;
    final h = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(latA) * math.cos(latB) * math.pow(math.sin(deltaLon / 2), 2);
    return 2 * radioTierra * math.asin(math.sqrt(h));
  }
}
