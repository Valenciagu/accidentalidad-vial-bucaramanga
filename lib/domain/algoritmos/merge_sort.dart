/// Merge Sort estable. Complejidad O(n log n) en todos los casos.
///
/// Devuelve una lista nueva. [comparar] sigue el contrato de `Comparable`.
List<T> mergeSort<T>(List<T> lista, int Function(T, T) comparar) {
  if (lista.length <= 1) return List.of(lista);

  final medio = lista.length ~/ 2;
  final izquierda = mergeSort(lista.sublist(0, medio), comparar);
  final derecha = mergeSort(lista.sublist(medio), comparar);
  return _mezclar(izquierda, derecha, comparar);
}

List<T> _mezclar<T>(
  List<T> izquierda,
  List<T> derecha,
  int Function(T, T) comparar,
) {
  final resultado = <T>[];
  var i = 0;
  var j = 0;

  while (i < izquierda.length && j < derecha.length) {
    if (comparar(izquierda[i], derecha[j]) <= 0) {
      resultado.add(izquierda[i]);
      i++;
    } else {
      resultado.add(derecha[j]);
      j++;
    }
  }

  resultado.addAll(izquierda.sublist(i));
  resultado.addAll(derecha.sublist(j));
  return resultado;
}
