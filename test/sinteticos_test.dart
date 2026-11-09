import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppi_analisis/configuracion.dart';
import 'package:ppi_analisis/data/generadores/generador_sintetico.dart';
import 'package:ppi_analisis/data/modelos/conjunto_accidentes_modelo.dart';
import 'package:ppi_analisis/domain/casos_uso/consultar_accidentes.dart';
import 'package:ppi_analisis/domain/entidades/cantidad_registros.dart';
import 'package:ppi_analisis/domain/entidades/conjunto_accidentes.dart';
import 'package:ppi_analisis/domain/entidades/filtros.dart';

void main() {
  const total = GeneradorSintetico.totalDisponible;

  group('Validación de la cantidad configurada', () {
    test('la cantidad configurada está en el rango y no genera aviso', () {
      // La CI falla si se publica la app con un valor que dispara el aviso.
      final c = CantidadRegistros.validar(cantidadAccidentes, disponibles: total);
      expect(c.usada, cantidadAccidentes);
      expect(c.aviso, isNull);
    });

    test('valores dentro del rango se usan tal cual', () {
      for (final pedida in [1, 102356, 300000, total]) {
        final c = CantidadRegistros.validar(pedida, disponibles: total);
        expect(c.usada, pedida);
        expect(c.corregida, isFalse);
      }
    });

    test('menor o igual a 0 avisa y usa 1', () {
      for (final pedida in [0, -1, -500000]) {
        final c = CantidadRegistros.validar(pedida, disponibles: total);
        expect(c.usada, 1);
        expect(c.aviso, contains('No hay esa cantidad de elementos en la lista'));
      }
    });

    test('mayor que 1.100.000 avisa y usa 1.100.000', () {
      final c = CantidadRegistros.validar(total + 1, disponibles: total);
      expect(c.usada, total);
      expect(c.aviso, contains('No hay esa cantidad de elementos en la lista'));
      expect(c.aviso, contains('1.100.000'));
    });
  });

  group('Generador sintético', () {
    late ConjuntoAccidentes reales;

    setUpAll(() {
      final texto = File('assets/datos/accidentes.json').readAsStringSync();
      reales = ConjuntoAccidentesModelo.desdeJson(
        jsonDecode(texto) as Map<String, dynamic>,
      );
    });

    void comprobarTabla(ConjuntoAccidentes datos) {
      for (var i = 1; i < datos.n; i++) {
        expect(datos.fechas[i] >= datos.fechas[i - 1], isTrue,
            reason: 'desordenado en $i');
      }
      expect(datos.fechas.first >= reales.fechas.first, isTrue);
      expect(datos.fechas.last <= reales.fechas.last, isTrue);
      for (var i = 0; i < datos.n; i++) {
        expect(datos.barrios[i] < reales.catalogoBarrios.length, isTrue);
      }
    }

    test('toma exactamente la cantidad pedida', () {
      for (final cantidad in [1, 7, 20000, reales.n, 102356, 300000]) {
        final datos = GeneradorSintetico.tomar(reales, cantidad);
        expect(datos.n, cantidad);
        expect(datos.sinteticos, cantidad > reales.n ? cantidad - reales.n : 0);
      }
    });

    test('con 39.168 devuelve los datos reales sin cambios', () {
      expect(identical(GeneradorSintetico.tomar(reales, reales.n), reales), isTrue);
    });

    test('rechaza cantidades fuera de rango', () {
      expect(() => GeneradorSintetico.tomar(reales, 0), throwsRangeError);
      expect(() => GeneradorSintetico.tomar(reales, total + 1), throwsRangeError);
    });

    test('es reproducible y la tabla queda ordenada y válida', () {
      final a = GeneradorSintetico.tomar(reales, 102356);
      final b = GeneradorSintetico.tomar(reales, 102356);
      expect(a.fechas, b.fechas);
      expect(a.barrios, b.barrios);
      comprobarTabla(a);
      comprobarTabla(GeneradorSintetico.tomar(reales, 20000));
    });

    test('los sintéticos caen en el día de la semana que declaran', () {
      final datos = GeneradorSintetico.tomar(reales, 200000);
      var distintos = 0;
      for (var i = 0; i < datos.n; i++) {
        final f = datos.fechas[i];
        final dia = DateTime.utc(f ~/ 10000, f ~/ 100 % 100, f % 100).weekday;
        if (dia != datos.dias[i]) distintos++;
      }
      // Solo pueden fallar los reales con fecha inconsistente desde el CSV.
      var distintosReales = 0;
      for (var i = 0; i < reales.n; i++) {
        final f = reales.fechas[i];
        final dia = DateTime.utc(f ~/ 10000, f ~/ 100 % 100, f % 100).weekday;
        if (dia != reales.dias[i]) distintosReales++;
      }
      expect(distintos, distintosReales);
    });

    test('más cantidad contiene a la de menos: los reales completos y los mismos sintéticos', () {
      const consultar = ConsultarAccidentes();
      final menor = consultar(GeneradorSintetico.tomar(reales, 102356), Filtros.ninguno);
      final mayor = consultar(GeneradorSintetico.tomar(reales, 300000), Filtros.ninguno);
      final soloReales = consultar(reales, Filtros.ninguno);
      for (var b = 0; b < soloReales.porBarrio.length; b++) {
        expect(menor.porBarrio[b] >= soloReales.porBarrio[b], isTrue);
        expect(mayor.porBarrio[b] >= menor.porBarrio[b], isTrue);
      }
    });

    test('las proporciones se parecen a las reales', () {
      const consultar = ConsultarAccidentes();
      final real = consultar(reales, Filtros.ninguno);
      final sintetico = consultar(GeneradorSintetico.tomar(reales, total), Filtros.ninguno);
      expect(sintetico.total, total);
      final proporcionReal = real.graves / real.total;
      final proporcionSintetica = sintetico.graves / sintetico.total;
      expect((proporcionReal - proporcionSintetica).abs(), lessThan(0.01));
      for (var a = 0; a < real.porAnio.length; a++) {
        final pr = real.porAnio[a] / real.total;
        final ps = sintetico.porAnio[a] / sintetico.total;
        expect((pr - ps).abs(), lessThan(0.005), reason: 'año ${reales.anioMinimo + a}');
      }
    });

    test('genera el total de 1.100.000 en un tiempo razonable', () {
      final reloj = Stopwatch()..start();
      final datos = GeneradorSintetico.tomar(reales, total);
      // ignore: avoid_print
      print('1.100.000 registros en ${reloj.elapsedMilliseconds} ms');
      expect(datos.n, total);
      comprobarTabla(datos);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
