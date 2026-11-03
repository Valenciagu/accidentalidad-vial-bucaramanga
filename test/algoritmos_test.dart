import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ppi_analisis/domain/algoritmos/busqueda_binaria.dart';
import 'package:ppi_analisis/domain/algoritmos/cobertura_maxima.dart';
import 'package:ppi_analisis/domain/algoritmos/merge_sort.dart';

/// Óptimo por fuerza bruta, independiente de la ramificación y poda.
int fuerzaBruta(InstanciaCobertura instancia) {
  var mejor = 0;

  void recorrer(int desde, List<int> elegidos) {
    mejor = math.max(mejor, verificarCobertura(instancia, elegidos));
    if (elegidos.length == instancia.k) return;
    for (var i = desde; i < instancia.m; i++) {
      final grupos = instancia.grupos;
      if (grupos != null && elegidos.any((e) => grupos[e] == grupos[i])) continue;
      recorrer(i + 1, [...elegidos, i]);
    }
  }

  recorrer(0, []);
  return mejor;
}

InstanciaCobertura instanciaAleatoria(math.Random azar, {bool conGrupos = false}) {
  final elementos = 8 + azar.nextInt(10);
  final m = 6 + azar.nextInt(7);
  return InstanciaCobertura(
    pesos: List.generate(elementos, (_) => azar.nextInt(20)),
    conjuntos: List.generate(m, (_) {
      return List.generate(elementos, (e) => e)
          .where((_) => azar.nextDouble() < 0.3)
          .toList();
    }),
    k: 1 + azar.nextInt(4),
    grupos: conGrupos ? List.generate(m, (_) => azar.nextInt(4)) : null,
  );
}

void main() {
  group('Búsqueda binaria', () {
    test('coincide con la búsqueda lineal, incluidos los duplicados', () {
      final azar = math.Random(1);
      for (var caso = 0; caso < 300; caso++) {
        final lista = List.generate(azar.nextInt(40), (_) => azar.nextInt(30))..sort();
        final objetivo = azar.nextInt(34) - 2;
        final lineal = lista.indexWhere((v) => v >= objetivo);
        expect(
          limiteInferior(lista, objetivo),
          lineal == -1 ? lista.length : lineal,
        );
      }
    });
  });

  group('Merge Sort', () {
    test('ordena igual que la librería estándar', () {
      final azar = math.Random(2);
      for (var caso = 0; caso < 100; caso++) {
        final lista = List.generate(azar.nextInt(200), (_) => azar.nextInt(50));
        expect(mergeSort(lista, (a, b) => a.compareTo(b)), List.of(lista)..sort());
      }
    });

    test('es estable', () {
      final pares = [(2, 'a'), (1, 'b'), (2, 'c'), (1, 'd')];
      expect(
        mergeSort(pares, (a, b) => a.$1.compareTo(b.$1)).map((p) => p.$2),
        ['b', 'd', 'a', 'c'],
      );
    });
  });

  group('Cobertura máxima', () {
    test('el exacto coincide con fuerza bruta en 300 instancias', () {
      final azar = math.Random(3);
      for (var caso = 0; caso < 300; caso++) {
        final instancia = instanciaAleatoria(azar);
        final exacto = resolverExacto(instancia);
        expect(exacto.optimoDemostrado, isTrue);
        expect(exacto.valor, fuerzaBruta(instancia), reason: 'caso $caso');
        expect(verificarCobertura(instancia, exacto.elegidos), exacto.valor);
      }
    });

    test('el voraz cumple la garantía 1 - 1/e', () {
      final azar = math.Random(4);
      for (var caso = 0; caso < 300; caso++) {
        final instancia = instanciaAleatoria(azar);
        final voraz = resolverVoraz(instancia);
        expect(voraz.valor, greaterThanOrEqualTo((1 - 1 / math.e) * fuerzaBruta(instancia)));
        expect(verificarCobertura(instancia, voraz.elegidos), voraz.valor);
      }
    });

    test('con grupos: exacto igual a fuerza bruta y voraz sobre la mitad', () {
      final azar = math.Random(6);
      for (var caso = 0; caso < 300; caso++) {
        final instancia = instanciaAleatoria(azar, conGrupos: true);
        final optimo = fuerzaBruta(instancia);
        final exacto = resolverExacto(instancia);
        final voraz = resolverVoraz(instancia);
        expect(exacto.valor, optimo, reason: 'caso $caso');
        expect(voraz.valor, greaterThanOrEqualTo(optimo / 2));
        for (final solucion in [exacto, voraz]) {
          final usados = solucion.elegidos.map((e) => instancia.grupos![e]);
          expect(usados.toSet(), hasLength(solucion.elegidos.length));
        }
      }
    });

    test('el voraz puede fallar: justifica tener el exacto', () {
      const instancia = InstanciaCobertura(
        pesos: [1, 1, 1, 1, 1, 1],
        conjuntos: [
          [0, 1, 2, 3],
          [0, 1, 4],
          [2, 3, 5],
        ],
        k: 2,
      );
      expect(resolverVoraz(instancia).valor, 5);
      expect(resolverExacto(instancia).valor, 6);
    });

    test('reducción: Conjunto Dominante se resuelve como Cobertura Máxima', () {
      // Estrella doble: 0 y 3 dominan el grafo; ningún vértice solo lo domina.
      const aristas = [(0, 1), (0, 2), (0, 3), (3, 4), (3, 5)];
      const vertices = 6;

      bool existeDominante(int k) {
        final vecindades = [
          for (var v = 0; v < vertices; v++)
            [
              v,
              for (final (a, b) in aristas) ...[if (a == v) b, if (b == v) a],
            ],
        ];
        final instancia = InstanciaCobertura(
          pesos: List.filled(vertices, 1),
          conjuntos: vecindades,
          k: k,
        );
        return resolverExacto(instancia).valor == vertices;
      }

      expect(existeDominante(1), isFalse);
      expect(existeDominante(2), isTrue);
    });

    test('devuelve mejor solución sin demostrar óptimo si se agota el tiempo', () {
      final azar = math.Random(5);
      final instancia = InstanciaCobertura(
        pesos: List.generate(120, (_) => 1 + azar.nextInt(9)),
        conjuntos: List.generate(150, (_) {
          return List.generate(120, (e) => e)
              .where((_) => azar.nextDouble() < 0.12)
              .toList();
        }),
        k: 15,
      );
      final solucion = resolverExacto(instancia, limiteMicrosegundos: 5000);
      expect(solucion.optimoDemostrado, isFalse);
      expect(solucion.valor, greaterThanOrEqualTo(resolverVoraz(instancia).valor));
    });

    test('combinaciones', () {
      expect(combinaciones(5, 2), 10);
      expect(combinaciones(204, 3), 1394204);
      expect(combinaciones(3, 5), 0);
    });
  });
}
