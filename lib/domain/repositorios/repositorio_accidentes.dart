import '../entidades/conjunto_accidentes.dart';

/// Contrato de acceso a los datos. La implementación vive en la capa `data`.
abstract interface class RepositorioAccidentes {
  Future<ConjuntoAccidentes> cargar();
}
