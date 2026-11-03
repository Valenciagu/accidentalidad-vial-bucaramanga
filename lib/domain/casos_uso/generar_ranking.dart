import '../algoritmos/merge_sort.dart';
import '../entidades/conjunto_accidentes.dart';
import '../entidades/resumen.dart';

/// Ordena las categorías por cantidad con Merge Sort: O(c log c), con c categorías.
class GenerarRanking {
  const GenerarRanking();

  List<ItemRanking> call(
    List<int> conteos,
    String Function(int indice) nombre, {
    bool ascendente = false,
  }) {
    final items = <ItemRanking>[
      for (var i = 0; i < conteos.length; i++)
        if (conteos[i] > 0)
          ItemRanking(indice: i, nombre: nombre(i), cantidad: conteos[i]),
    ];
    return mergeSort(
      items,
      (a, b) => ascendente
          ? a.cantidad.compareTo(b.cantidad)
          : b.cantidad.compareTo(a.cantidad),
    );
  }

  List<ItemRanking> comunas(ConjuntoAccidentes datos, Resumen resumen) {
    final conteos = List<int>.generate(
      resumen.porComuna.length,
      (i) => datos.catalogoComunas[i].tieneUbicacion ? resumen.porComuna[i] : 0,
    );
    return call(conteos, (i) => datos.catalogoComunas[i].etiqueta);
  }

  List<ItemRanking> barrios(ConjuntoAccidentes datos, Resumen resumen) {
    final conteos = List<int>.generate(
      resumen.porBarrio.length,
      (i) => datos.catalogoBarrios[i].tieneUbicacion ? resumen.porBarrio[i] : 0,
    );
    return call(conteos, (i) => datos.catalogoBarrios[i].nombre);
  }
}
