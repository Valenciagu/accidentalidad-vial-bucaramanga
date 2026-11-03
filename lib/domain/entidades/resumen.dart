import 'catalogos.dart';

/// Elemento de una lista ordenada por cantidad.
class ItemRanking {
  const ItemRanking({
    required this.indice,
    required this.nombre,
    required this.cantidad,
  });

  final int indice;
  final String nombre;
  final int cantidad;
}

const int horasPorSemana = 168;

/// Agregados de una consulta. Se llenan en una sola pasada sobre los registros.
class Resumen {
  Resumen({
    required this.anioBase,
    required int cantidadAnios,
    required int cantidadComunas,
    required int cantidadBarrios,
  }) : porAnio = List.filled(cantidadAnios, 0),
       porComuna = List.filled(cantidadComunas, 0),
       porBarrio = List.filled(cantidadBarrios, 0),
       serieMensual = List.filled(cantidadAnios * 12, 0),
       porComunaDiaHora = List.filled(cantidadComunas * horasPorSemana, 0);

  final int anioBase;
  int total = 0;
  int graves = 0;

  final List<int> porAnio;
  final List<int> porMes = List.filled(12, 0);
  final List<int> gravesPorMes = List.filled(12, 0);
  final List<int> porDia = List.filled(7, 0);
  final List<int> porHora = List.filled(24, 0);
  final List<int> porGravedad = List.filled(3, 0);
  final List<int> porVehiculo = List.filled(nombresVehiculos.length, 0);
  final List<int> porTipo = List.filled(3, 0);
  final List<int> porCantidadVehiculos = List.filled(4, 0);
  final List<int> porComuna;
  final List<int> porBarrio;
  final List<int> serieMensual;

  /// Celda `comuna * 168 + (día - 1) * 24 + hora`. Entrada del planificador.
  final List<int> porComunaDiaHora;
  int deEmpresa = 0;
  int reportadosPolicia = 0;

  double porcentaje(int valor) => total == 0 ? 0 : valor * 100 / total;

  /// Vehículo más frecuente sin contar peatones. Null si no hay accidentes.
  ItemRanking? get vehiculoPrincipal {
    var mejor = -1;
    for (var i = 0; i < porVehiculo.length; i++) {
      if (i == vehiculoPeaton) continue;
      if (porVehiculo[i] > 0 && (mejor < 0 || porVehiculo[i] > porVehiculo[mejor])) {
        mejor = i;
      }
    }
    if (mejor < 0) return null;
    return ItemRanking(
      indice: mejor,
      nombre: nombresVehiculos[mejor],
      cantidad: porVehiculo[mejor],
    );
  }

  int? get diaPrincipal => _posicionDelMayor(porDia);

  /// Hora de inicio de la franja de dos horas con más accidentes.
  int? get franjaPrincipal {
    if (total == 0) return null;
    var mejor = 0;
    var mayor = -1;
    for (var hora = 0; hora < 24; hora++) {
      final suma = porHora[hora] + porHora[(hora + 1) % 24];
      if (suma > mayor) {
        mayor = suma;
        mejor = hora;
      }
    }
    return mejor;
  }

  int cantidadEnFranja(int inicio) => porHora[inicio] + porHora[(inicio + 1) % 24];

  int? _posicionDelMayor(List<int> valores) {
    if (total == 0) return null;
    var mejor = 0;
    for (var i = 1; i < valores.length; i++) {
      if (valores[i] > valores[mejor]) mejor = i;
    }
    return mejor;
  }
}

/// Variación frente al mismo período del año anterior.
class Comparacion {
  const Comparacion({
    required this.anioReferencia,
    required this.variacionTotal,
    required this.variacionGraves,
    required this.periodoParcial,
  });

  final int anioReferencia;
  final double? variacionTotal;
  final double? variacionGraves;

  /// El año consultado no está completo y se comparan solo sus meses.
  final bool periodoParcial;
}
