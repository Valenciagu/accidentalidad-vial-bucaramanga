class EstadoServicio {
  const EstadoServicio({
    required this.nombre,
    required this.descripcion,
    required this.disponible,
    this.latenciaMs,
  });

  final String nombre;
  final String descripcion;
  final bool disponible;
  final int? latenciaMs;
}
