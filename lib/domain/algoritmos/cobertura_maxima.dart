import 'dart:math' as math;

/// Instancia de Cobertura Máxima ponderada.
///
/// Dado un universo con pesos y una colección de subconjuntos, elegir [k]
/// subconjuntos que maximicen el peso cubierto. Es NP-difícil; su versión de
/// decisión ("¿se puede cubrir al menos P con k subconjuntos?") es NP-completa.
///
/// Si se indican [grupos], se elige como máximo un subconjunto de cada grupo.
/// Sin grupos es el problema clásico; con ellos el problema sigue siendo
/// NP-difícil, pues el clásico es el caso en que cada subconjunto es su grupo.
class InstanciaCobertura {
  const InstanciaCobertura({
    required this.pesos,
    required this.conjuntos,
    required this.k,
    this.grupos,
  });

  final List<int> pesos;
  final List<List<int>> conjuntos;
  final int k;

  /// Grupo de cada subconjunto, o null si no hay restricción.
  final List<int>? grupos;

  int get m => conjuntos.length;
  int get pesoTotal => pesos.fold(0, (suma, peso) => suma + peso);
}

class SolucionCobertura {
  const SolucionCobertura({
    required this.elegidos,
    required this.valor,
    required this.nodos,
    required this.microsegundos,
    required this.optimoDemostrado,
  });

  final List<int> elegidos;
  final int valor;

  /// Estados explorados: la medida de trabajo que crece de forma exponencial.
  final int nodos;
  final int microsegundos;
  final bool optimoDemostrado;
}

int _ganancia(List<int> conjunto, List<int> pesos, List<int> cubiertos) {
  var ganancia = 0;
  for (final elemento in conjunto) {
    if (cubiertos[elemento] == 0) ganancia += pesos[elemento];
  }
  return ganancia;
}

/// Comprueba un certificado en tiempo polinomial, O(k·s): por esto el problema
/// de decisión pertenece a NP. [s] es el tamaño del mayor subconjunto.
int verificarCobertura(InstanciaCobertura instancia, List<int> elegidos) {
  final cubiertos = List<int>.filled(instancia.pesos.length, 0);
  var valor = 0;
  for (final indice in elegidos) {
    for (final elemento in instancia.conjuntos[indice]) {
      if (cubiertos[elemento] == 0) {
        cubiertos[elemento] = 1;
        valor += instancia.pesos[elemento];
      }
    }
  }
  return valor;
}

/// Algoritmo voraz: en cada ronda toma el subconjunto con mayor ganancia.
///
/// Complejidad O(k·m·s), polinomial. Garantiza al menos (1 - 1/e) ≈ 63 % del
/// óptimo sin grupos (Nemhauser, Wolsey y Fisher, 1978) y al menos 50 % con
/// grupos (Fisher, Nemhauser y Wolsey, 1978).
SolucionCobertura resolverVoraz(InstanciaCobertura instancia) {
  final reloj = Stopwatch()..start();
  final cubiertos = List<int>.filled(instancia.pesos.length, 0);
  final elegidos = <int>[];
  final gruposUsados = <int>{};
  var valor = 0;
  var nodos = 0;

  for (var ronda = 0; ronda < instancia.k; ronda++) {
    var mejor = -1;
    var mejorGanancia = 0;
    for (var i = 0; i < instancia.m; i++) {
      if (gruposUsados.contains(instancia.grupos?[i])) continue;
      nodos++;
      final ganancia = _ganancia(instancia.conjuntos[i], instancia.pesos, cubiertos);
      if (ganancia > mejorGanancia) {
        mejorGanancia = ganancia;
        mejor = i;
      }
    }
    if (mejor < 0) break;
    elegidos.add(mejor);
    if (instancia.grupos != null) gruposUsados.add(instancia.grupos![mejor]);
    valor += mejorGanancia;
    for (final elemento in instancia.conjuntos[mejor]) {
      cubiertos[elemento] = 1;
    }
  }

  return SolucionCobertura(
    elegidos: elegidos,
    valor: valor,
    nodos: nodos,
    microsegundos: reloj.elapsedMicroseconds,
    optimoDemostrado: false,
  );
}

/// Ramificación y poda. Encuentra el óptimo exacto; en el peor caso explora
/// C(m, k) combinaciones, exponencial cuando k crece con m.
///
/// Cota: la ganancia es submodular, así que lo que falta por cubrir no supera
/// la suma de las mayores ganancias individuales de los candidatos restantes.
/// Si se agota [limiteMicrosegundos] devuelve la mejor solución encontrada con
/// `optimoDemostrado` en falso.
SolucionCobertura resolverExacto(
  InstanciaCobertura instancia, {
  int limiteMicrosegundos = 3000000,
}) {
  final reloj = Stopwatch()..start();
  final inicial = resolverVoraz(instancia);

  var mejorValor = inicial.valor;
  var mejorElegidos = List<int>.of(inicial.elegidos);
  var nodos = 0;
  var agotado = false;

  final cubiertos = List<int>.filled(instancia.pesos.length, 0);
  final actuales = <int>[];
  final gruposUsados = <int>{};

  void explorar(List<int> candidatos, int valor, int restantes) {
    if (agotado) return;
    nodos++;
    if (reloj.elapsedMicroseconds > limiteMicrosegundos) {
      agotado = true;
      return;
    }
    if (valor > mejorValor) {
      mejorValor = valor;
      mejorElegidos = List<int>.of(actuales);
    }
    if (restantes == 0 || candidatos.isEmpty) return;

    final conGanancia = <int>[];
    final ganancias = <int>[];
    for (final candidato in candidatos) {
      if (gruposUsados.contains(instancia.grupos?[candidato])) continue;
      final ganancia = _ganancia(instancia.conjuntos[candidato], instancia.pesos, cubiertos);
      if (ganancia > 0) {
        conGanancia.add(candidato);
        ganancias.add(ganancia);
      }
    }
    final orden = List<int>.generate(conGanancia.length, (i) => i)
      ..sort((a, b) => ganancias[b].compareTo(ganancias[a]));

    for (var posicion = 0; posicion < orden.length; posicion++) {
      var cota = valor;
      final limite = math.min(posicion + restantes, orden.length);
      for (var i = posicion; i < limite; i++) {
        cota += ganancias[orden[i]];
      }
      if (cota <= mejorValor) return;

      final elegido = conGanancia[orden[posicion]];
      final marcados = <int>[];
      for (final elemento in instancia.conjuntos[elegido]) {
        if (cubiertos[elemento] == 0) {
          cubiertos[elemento] = 1;
          marcados.add(elemento);
        }
      }
      actuales.add(elegido);
      final grupo = instancia.grupos?[elegido];
      if (grupo != null) gruposUsados.add(grupo);

      explorar(
        [for (var i = posicion + 1; i < orden.length; i++) conGanancia[orden[i]]],
        valor + ganancias[orden[posicion]],
        restantes - 1,
      );

      actuales.removeLast();
      gruposUsados.remove(grupo);
      for (final elemento in marcados) {
        cubiertos[elemento] = 0;
      }
      if (agotado) return;
    }
  }

  explorar(List<int>.generate(instancia.m, (i) => i), 0, instancia.k);

  return SolucionCobertura(
    elegidos: mejorElegidos,
    valor: mejorValor,
    nodos: nodos,
    microsegundos: reloj.elapsedMicroseconds,
    optimoDemostrado: !agotado,
  );
}

/// Combinaciones C(m, k) en doble precisión, para reportar el espacio de búsqueda.
double combinaciones(int m, int k) {
  if (k < 0 || k > m) return 0;
  var resultado = 1.0;
  for (var i = 1; i <= k; i++) {
    resultado = resultado * (m - k + i) / i;
  }
  return resultado;
}
