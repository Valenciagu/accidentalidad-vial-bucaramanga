/// Criterios de consulta combinables (RF-05). Un campo nulo significa "todos".
class Filtros {
  const Filtros({
    this.anioDesde,
    this.anioHasta,
    this.mes,
    this.mascaraDias,
    this.horaDesde,
    this.horaHasta,
    this.comuna,
    this.barrio,
    this.mascaraGravedad,
    this.vehiculo,
  });

  static const Filtros ninguno = Filtros();

  final int? anioDesde;
  final int? anioHasta;

  /// Mes de 1 a 12.
  final int? mes;

  /// Bit i encendido: incluye el día i+1 de la semana (1 = lunes).
  final int? mascaraDias;
  final int? horaDesde;
  final int? horaHasta;

  /// Posición en el catálogo de comunas.
  final int? comuna;

  /// Posición en el catálogo de barrios.
  final int? barrio;
  final int? mascaraGravedad;

  /// Bit de la columna `mascara`.
  final int? vehiculo;

  bool get vacio =>
      anioDesde == null &&
      anioHasta == null &&
      mes == null &&
      mascaraDias == null &&
      horaDesde == null &&
      horaHasta == null &&
      comuna == null &&
      barrio == null &&
      mascaraGravedad == null &&
      vehiculo == null;

  bool get anioUnico => anioDesde != null && anioDesde == anioHasta;

  int get cantidadActivos {
    var activos = 0;
    if (anioDesde != null || anioHasta != null) activos++;
    if (mes != null) activos++;
    if (mascaraDias != null) activos++;
    if (horaDesde != null || horaHasta != null) activos++;
    if (comuna != null) activos++;
    if (barrio != null) activos++;
    if (mascaraGravedad != null) activos++;
    if (vehiculo != null) activos++;
    return activos;
  }

  Filtros copiarCon({
    int? anioDesde,
    int? anioHasta,
    int? mes,
    int? mascaraDias,
    int? horaDesde,
    int? horaHasta,
    int? comuna,
    int? barrio,
    int? mascaraGravedad,
    int? vehiculo,
  }) {
    return Filtros(
      anioDesde: anioDesde ?? this.anioDesde,
      anioHasta: anioHasta ?? this.anioHasta,
      mes: mes ?? this.mes,
      mascaraDias: mascaraDias ?? this.mascaraDias,
      horaDesde: horaDesde ?? this.horaDesde,
      horaHasta: horaHasta ?? this.horaHasta,
      comuna: comuna ?? this.comuna,
      barrio: barrio ?? this.barrio,
      mascaraGravedad: mascaraGravedad ?? this.mascaraGravedad,
      vehiculo: vehiculo ?? this.vehiculo,
    );
  }
}
