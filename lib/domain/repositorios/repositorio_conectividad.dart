import '../entidades/estado_servicio.dart';

/// Contrato para consultar la disponibilidad de los servicios externos (RF-11).
abstract interface class RepositorioConectividad {
  Future<List<EstadoServicio>> verificar();
}
