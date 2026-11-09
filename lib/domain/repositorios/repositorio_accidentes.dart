import '../entidades/conjunto_accidentes.dart';

/// Contrato de acceso a los datos. La implementación vive en la capa `data`.
abstract interface class RepositorioAccidentes {
  /// Máximo de accidentes que se pueden cargar.
  int get disponibles;

  /// Carga exactamente [cantidad] accidentes, con 1 <= cantidad <= [disponibles].
  Future<ConjuntoAccidentes> cargar(int cantidad);
}
