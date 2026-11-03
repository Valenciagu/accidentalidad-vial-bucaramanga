/// Primera posición cuyo valor es >= [objetivo]. Complejidad O(log n).
///
/// Requiere que [valores] esté ordenado de forma ascendente.
int limiteInferior(List<int> valores, int objetivo) {
  var inicio = 0;
  var fin = valores.length;
  while (inicio < fin) {
    final medio = (inicio + fin) ~/ 2;
    if (valores[medio] < objetivo) {
      inicio = medio + 1;
    } else {
      fin = medio;
    }
  }
  return inicio;
}
