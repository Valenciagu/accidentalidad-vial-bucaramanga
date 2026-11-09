import '../../core/formato.dart';

/// Cantidad de accidentes que se pidió cargar y la que realmente se usa.
///
/// Si la cantidad pedida está fuera de 1..disponibles se corrige y se deja un
/// [aviso] para mostrarlo en pantalla: menor o igual a 0 usa 1, y mayor que lo
/// disponible usa el máximo.
class CantidadRegistros {
  const CantidadRegistros._(this.pedida, this.usada, this.aviso);

  factory CantidadRegistros.validar(int pedida, {required int disponibles}) {
    if (pedida <= 0) {
      return CantidadRegistros._(pedida, 1, _mensaje(pedida, disponibles, 1));
    }
    if (pedida > disponibles) {
      return CantidadRegistros._(
        pedida,
        disponibles,
        _mensaje(pedida, disponibles, disponibles),
      );
    }
    return CantidadRegistros._(pedida, pedida, null);
  }

  final int pedida;
  final int usada;
  final String? aviso;

  bool get corregida => aviso != null;

  static String _mensaje(int pedida, int disponibles, int usada) =>
      'No hay esa cantidad de elementos en la lista: se pidieron '
      '${formatoNumero(pedida)} y solo hay de 1 a ${formatoNumero(disponibles)}. '
      'Se cargan ${formatoNumero(usada)}.';
}
